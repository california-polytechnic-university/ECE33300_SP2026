using System;
using System.Drawing;
using System.Globalization;
using System.IO.Ports;
using System.Windows.Forms;

namespace DealOrNoDealUINEW
{
    public partial class Form1 : Form
    {

        private Label[] caseBoxes = new Label[16];
        private Label[] moneyLabels = new Label[16];

        private ComboBox caseDropdown;
        private Button previewButton;
        private Button confirmButton;
        private Button dealButton;
        private Button noDealButton;
        private Button resetButton;

        private SerialPort serialPort;

        private Label previewLabel;
        private Label selectedLabel;
        private Label openedValueLabel;
        private Label remainingTotalLabel;
        private Label remainingAverageLabel;
        private Label offerLabel;
        private Label statusLabel;

        private int previewCase = -1;
        private int selectedCase = -1;
        private int bankerOffer = 0;
        private int remainingTotal = 0;
        private int remainingAverage = 0;

        // Match this table to your Verilog prize_logic.v.
        private int[] caseValues =
        {
            1,
            5,
            10,
            25,
            50,
            75,
            100,
            200,
            300,
            400,
            500,
            750,
            1000,
            5000,
            10000,
            100000
        };

        private bool[] caseOpened = new bool[16];

        public Form1()
        {
            // InitializeComponent();
            BuildUI();
            ResetBoard();

            // Comment this out if you want to test UI without the board connected.
            SetupSerial();
        }




        private void SetupSerial()
        {
            try
            {
                serialPort = new SerialPort();

                // Change this to the COM port shown in Device Manager.
                serialPort.PortName = "COM4";

                // Must match your Verilog uart_tx baud rate.
                serialPort.BaudRate = 3000000;
                serialPort.DataBits = 8;
                serialPort.Parity = Parity.None;
                serialPort.StopBits = StopBits.One;
                serialPort.Handshake = Handshake.None;

                serialPort.NewLine = "\n";
                serialPort.DataReceived += SerialPort_DataReceived;
                serialPort.Open();

                statusLabel.Text = "Connected to " + serialPort.PortName;
            }
            catch (Exception ex)
            {
                statusLabel.Text = "Serial error: " + ex.Message;
            }
        }

        private void SerialPort_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            try
            {
                string message = serialPort.ReadLine().Trim();

                this.BeginInvoke(new Action(() =>
                {
                    HandleMessage(message);
                }));
            }
            catch
            {
                // Ignore incomplete serial messages.
            }
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (serialPort != null && serialPort.IsOpen)
                serialPort.Close();

            base.OnFormClosing(e);
        }
        private void HandleGameStateMessage(string message)
        {
            if (!int.TryParse(message.Substring(1), out int state))
            {
                statusLabel.Text = "Bad state message: " + message;
                return;
            }

            switch (state)
            {
                case 0: // START
                    statusLabel.Text = "Game starting...";
                    break;
                case 1: // CHOOSE_PLAYER_CASE
                    statusLabel.Text = "Choose your case!";
                    offerLabel.Text = "Banker Offer: --";
                    break;
                case 2: // OPEN_CASE
                    statusLabel.Text = "Open a case.";
                    break;
                case 3: // BANKER_OFFER
                    statusLabel.Text = "Banker is making an offer...";
                    break;
                case 4: // DEAL_OR_NO_DEAL
                    statusLabel.Text = "Deal or No Deal?";
                    offerLabel.ForeColor = Color.Gold;
                    break;
                case 5: // FINAL_REVEAL
                    statusLabel.Text = "Final reveal!";
                    break;
                case 6: // GAME_OVER
                    statusLabel.Text = "Game over!";
                    DisableGameButtonsAfterDeal();
                    break;
                case 7: // INVALID_CASE
                    statusLabel.Text = "Invalid case — already opened!";
                    break;
                default:
                    statusLabel.Text = "Unknown state: " + state;
                    break;
            }
        }
        private void BuildUI()
        {
            this.Text = "Deal or No Deal FPGA UI";
            this.ClientSize = new Size(1120, 760);
            this.BackColor = Color.Black;
            this.StartPosition = FormStartPosition.CenterScreen;

            Label title = new Label();
            title.Text = "DEAL OR NO DEAL";
            title.ForeColor = Color.White;
            title.Font = new Font("Arial", 28, FontStyle.Bold);
            title.TextAlign = ContentAlignment.MiddleCenter;
            title.SetBounds(0, 20, 1120, 50);
            this.Controls.Add(title);

            BuildCaseBoard();
            BuildMoneyBoard();
            BuildStatusLabels();
            BuildControlButtons();
        }

        private void BuildCaseBoard()
        {
            int startX = 80;
            int startY = 110;
            int boxW = 100;
            int boxH = 60;
            int gap = 18;

            for (int i = 0; i < 16; i++)
            {
                int row = i / 4;
                int col = i % 4;

                Label box = new Label();
                box.Text = i.ToString("D2");
                box.Font = new Font("Arial", 18, FontStyle.Bold);
                box.BackColor = Color.RoyalBlue;
                box.ForeColor = Color.White;
                box.TextAlign = ContentAlignment.MiddleCenter;
                box.BorderStyle = BorderStyle.FixedSingle;

                box.SetBounds(
                    startX + col * (boxW + gap),
                    startY + row * (boxH + gap),
                    boxW,
                    boxH
                );

                caseBoxes[i] = box;
                this.Controls.Add(box);
            }
        }

        private void BuildMoneyBoard()
        {
            Label moneyTitle = new Label();
            moneyTitle.Text = "MONEY BOARD";
            moneyTitle.ForeColor = Color.White;
            moneyTitle.Font = new Font("Arial", 18, FontStyle.Bold);
            moneyTitle.TextAlign = ContentAlignment.MiddleCenter;
            moneyTitle.SetBounds(720, 95, 280, 35);
            this.Controls.Add(moneyTitle);

            int startX = 720;
            int startY = 140;
            int labelW = 280;
            int labelH = 25;
            int gap = 5;

            for (int i = 0; i < 16; i++)
            {
                Label money = new Label();
                money.Text = "$" + caseValues[i].ToString("N0", CultureInfo.InvariantCulture);
                money.Font = new Font("Arial", 11, FontStyle.Bold);
                money.BackColor = Color.DarkBlue;
                money.ForeColor = Color.White;
                money.TextAlign = ContentAlignment.MiddleCenter;
                money.BorderStyle = BorderStyle.FixedSingle;

                money.SetBounds(
                    startX,
                    startY + i * (labelH + gap),
                    labelW,
                    labelH
                );

                moneyLabels[i] = money;
                this.Controls.Add(money);
            }
        }
        


        private void BuildStatusLabels()
        {
            previewLabel = new Label();
            previewLabel.Text = "Preview: --";
            previewLabel.ForeColor = Color.White;
            previewLabel.Font = new Font("Arial", 15, FontStyle.Bold);
            previewLabel.SetBounds(80, 455, 200, 30);
            this.Controls.Add(previewLabel);

            selectedLabel = new Label();
            selectedLabel.Text = "Selected: --";
            selectedLabel.ForeColor = Color.White;
            selectedLabel.Font = new Font("Arial", 15, FontStyle.Bold);
            selectedLabel.SetBounds(290, 455, 230, 30);
            this.Controls.Add(selectedLabel);

            openedValueLabel = new Label();
            openedValueLabel.Text = "Opened Value: --";
            openedValueLabel.ForeColor = Color.White;
            openedValueLabel.Font = new Font("Arial", 15, FontStyle.Bold);
            openedValueLabel.SetBounds(80, 495, 350, 30);
            this.Controls.Add(openedValueLabel);

            remainingTotalLabel = new Label();
            remainingTotalLabel.Text = "Remaining Total: --";
            remainingTotalLabel.ForeColor = Color.LightGray;
            remainingTotalLabel.Font = new Font("Arial", 13, FontStyle.Bold);
            remainingTotalLabel.SetBounds(80, 535, 350, 30);
            this.Controls.Add(remainingTotalLabel);

            remainingAverageLabel = new Label();
            remainingAverageLabel.Text = "Remaining Average: --";
            remainingAverageLabel.ForeColor = Color.LightGray;
            remainingAverageLabel.Font = new Font("Arial", 13, FontStyle.Bold);
            remainingAverageLabel.SetBounds(450, 535, 350, 30);
            this.Controls.Add(remainingAverageLabel);

            offerLabel = new Label();
            offerLabel.Text = "Banker Offer: --";
            offerLabel.ForeColor = Color.Gold;
            offerLabel.Font = new Font("Arial", 17, FontStyle.Bold);
            offerLabel.SetBounds(80, 575, 500, 35);
            this.Controls.Add(offerLabel);

            statusLabel = new Label();
            statusLabel.Text = "UI ready. Waiting for FPGA messages.";
            statusLabel.ForeColor = Color.LightGray;
            statusLabel.Font = new Font("Arial", 11, FontStyle.Regular);
            statusLabel.SetBounds(80, 615, 960, 30);
            this.Controls.Add(statusLabel);
        }

        private void BuildControlButtons()
        {
            int controlY = 690;

            caseDropdown = new ComboBox();
            caseDropdown.Font = new Font("Arial", 12, FontStyle.Regular);
            caseDropdown.DropDownStyle = ComboBoxStyle.DropDownList;
            caseDropdown.SetBounds(80, controlY, 80, 30);

            for (int i = 0; i < 16; i++)
            {
                caseDropdown.Items.Add(i.ToString("D2"));
            }

            caseDropdown.SelectedIndex = 0;
            this.Controls.Add(caseDropdown);

            previewButton = new Button();
            previewButton.Text = "Preview";
            previewButton.ForeColor = Color.White;
            previewButton.BackColor = Color.DimGray;
            previewButton.UseVisualStyleBackColor = false;
            previewButton.Font = new Font("Arial", 10, FontStyle.Bold);
            previewButton.SetBounds(180, controlY, 100, 30);
            previewButton.Click += PreviewButton_Click;
            this.Controls.Add(previewButton);

            confirmButton = new Button();
            confirmButton.Text = "Confirm";
            confirmButton.ForeColor = Color.White;
            confirmButton.BackColor = Color.DimGray;
            confirmButton.UseVisualStyleBackColor = false;
            confirmButton.Font = new Font("Arial", 10, FontStyle.Bold);
            confirmButton.SetBounds(290, controlY, 100, 30);
            confirmButton.Click += ConfirmButton_Click;
            this.Controls.Add(confirmButton);

            dealButton = new Button();
            dealButton.Text = "Deal";
            dealButton.ForeColor = Color.White;
            dealButton.BackColor = Color.DarkGreen;
            dealButton.UseVisualStyleBackColor = false;
            dealButton.Font = new Font("Arial", 10, FontStyle.Bold);
            dealButton.SetBounds(420, controlY, 100, 30);
            dealButton.Click += DealButton_Click;
            this.Controls.Add(dealButton);

            noDealButton = new Button();
            noDealButton.Text = "No Deal";
            noDealButton.ForeColor = Color.White;
            noDealButton.BackColor = Color.DarkRed;
            noDealButton.UseVisualStyleBackColor = false;
            noDealButton.Font = new Font("Arial", 10, FontStyle.Bold);
            noDealButton.SetBounds(530, controlY, 100, 30);
            noDealButton.Click += NoDealButton_Click;
            this.Controls.Add(noDealButton);

            resetButton = new Button();
            resetButton.Text = "Reset";
            resetButton.ForeColor = Color.White;
            resetButton.BackColor = Color.DimGray;
            resetButton.UseVisualStyleBackColor = false;
            resetButton.Font = new Font("Arial", 10, FontStyle.Bold);
            resetButton.SetBounds(660, controlY, 100, 30);
            resetButton.Click += ResetButton_Click;
            this.Controls.Add(resetButton);
        }

        private void PreviewButton_Click(object sender, EventArgs e)
        {
            int caseNumber = caseDropdown.SelectedIndex;
            HandleMessage("P" + caseNumber.ToString("D2"));
        }

        private void ConfirmButton_Click(object sender, EventArgs e)
        {
            int caseNumber = caseDropdown.SelectedIndex;
            HandleMessage("C" + caseNumber.ToString("D2"));
        }

        private void DealButton_Click(object sender, EventArgs e)
        {
            HandleMessage("D");
        }

        private void NoDealButton_Click(object sender, EventArgs e)
        {
            HandleMessage("N");
        }

        private void ResetButton_Click(object sender, EventArgs e)
        {
            HandleMessage("R");
        }

        private void HandleMessage(string message)
        {
            if (string.IsNullOrWhiteSpace(message))
                return;

            message = message.Trim();

            if (message == "R")
            {
                ResetBoard();
                statusLabel.Text = "Game reset";
                return;
            }

            if (message == "D")
            {
                statusLabel.Text = "DEAL accepted. You accepted $" + bankerOffer.ToString("N0", CultureInfo.InvariantCulture) + ".";
                DisableGameButtonsAfterDeal();
                
                return;
            }

            if (message == "N")
            {
                statusLabel.Text = "NO DEAL. Keep opening cases.";
                
                return;
            }

            /*
                Supported messages:

                Current FPGA messages:
                    P06          preview case 06
                    C06          confirmed case 06
                    I06          invalid case 06

                Future FPGA messages:
                    O7338        banker offer = $7,338
                    A7338        remaining average = $7,338
                    T117416      remaining total = $117,416
                    V06,100      case 06 opened value = $100
            */

            char command = message[0];

            if (command == 'O')
            {
                HandleBankerOfferMessage(message);
                return;
            }

            if (command == 'A')
            {
                HandleRemainingAverageMessage(message);
                return;
            }

            if (command == 'T')
            {
                HandleRemainingTotalMessage(message);
                return;
            }

            if (command == 'V')
            {
                HandleOpenedValueMessage(message);
                return;
            }
            if (command == 'S')
            {
                HandleGameStateMessage(message);
                return;
            }
            if (message.Length < 3)
            {
                statusLabel.Text = "Unknown message: " + message;
                return;
            }

            bool parsed = int.TryParse(message.Substring(1, 2), out int caseNumber);

            if (!parsed || caseNumber < 0 || caseNumber > 15)
            {
                statusLabel.Text = "Bad case message: " + message;
                return;
            }

            switch (command)
            {
                case 'P':
                    SetPreviewCase(caseNumber);
                    break;

                case 'C':
                    ConfirmCase(caseNumber);
                    break;

                case 'I':
                    ShowInvalidCase(caseNumber);
                    break;

                default:
                    statusLabel.Text = "Unknown command: " + message;
                    break;
            }
        }

        private void HandleBankerOfferMessage(string message)
        {
            string amountText = message.Substring(1);

            if (int.TryParse(amountText, out int amount))
            {
                bankerOffer = amount;
                offerLabel.Text = "Banker Offer: $" + bankerOffer.ToString("N0", CultureInfo.InvariantCulture);
                statusLabel.Text = "Banker offer received: $" + bankerOffer.ToString("N0", CultureInfo.InvariantCulture);
            }
            else
            {
                statusLabel.Text = "Bad banker offer message: " + message;
            }
        }

        private void HandleRemainingAverageMessage(string message)
        {
            string amountText = message.Substring(1);

            if (int.TryParse(amountText, out int amount))
            {
                remainingAverage = amount;
                remainingAverageLabel.Text = "Remaining Average: $" + remainingAverage.ToString("N0", CultureInfo.InvariantCulture);
                statusLabel.Text = "Remaining average received: $" + remainingAverage.ToString("N0", CultureInfo.InvariantCulture);
            }
            else
            {
                statusLabel.Text = "Bad average message: " + message;
            }
        }

        private void HandleRemainingTotalMessage(string message)
        {
            string amountText = message.Substring(1);

            if (int.TryParse(amountText, out int amount))
            {
                remainingTotal = amount;
                remainingTotalLabel.Text = "Remaining Total: $" + remainingTotal.ToString("N0", CultureInfo.InvariantCulture);
                statusLabel.Text = "Remaining total received: $" + remainingTotal.ToString("N0", CultureInfo.InvariantCulture);
            }
            else
            {
                statusLabel.Text = "Bad total message: " + message;
            }
        }

        private void HandleOpenedValueMessage(string message)
        {
            // Expected format: V06,100
            string payload = message.Substring(1);
            string[] pieces = payload.Split(',');

            if (pieces.Length != 2)
            {
                statusLabel.Text = "Bad opened value message: " + message;
                return;
            }

            bool caseParsed = int.TryParse(pieces[0], out int caseNumber);
            bool valueParsed = int.TryParse(pieces[1], out int value);

            if (!caseParsed || !valueParsed || caseNumber < 0 || caseNumber > 15)
            {
                statusLabel.Text = "Bad opened value message: " + message;
                return;
            }

            openedValueLabel.Text = "Opened Value: Case " + caseNumber.ToString("D2") +
                                    " = $" + value.ToString("N0", CultureInfo.InvariantCulture);

            statusLabel.Text = "Opened value received for case " + caseNumber.ToString("D2") +
                               ": $" + value.ToString("N0", CultureInfo.InvariantCulture);
        }

        private void SetPreviewCase(int caseNumber)
        {
            previewCase = caseNumber;
            previewLabel.Text = "Preview: " + caseNumber.ToString("D2");
            statusLabel.Text = "Previewing case " + caseNumber.ToString("D2");

            RedrawBoard();
            
        }

        private void ConfirmCase(int caseNumber)
        {
            selectedCase = caseNumber;
            caseOpened[caseNumber] = true;

            selectedLabel.Text = "Selected: " + caseNumber.ToString("D2");

            int value = caseValues[caseNumber];

            openedValueLabel.Text = "Opened Value: Case " + caseNumber.ToString("D2") +
                                    " = $" + value.ToString("N0", CultureInfo.InvariantCulture);

            statusLabel.Text = "Confirmed case " + caseNumber.ToString("D2") +
                               " with value $" + value.ToString("N0", CultureInfo.InvariantCulture);

            caseBoxes[caseNumber].BackColor = Color.Gray;
            caseBoxes[caseNumber].ForeColor = Color.White;

            moneyLabels[caseNumber].BackColor = Color.DimGray;
            moneyLabels[caseNumber].ForeColor = Color.LightGray;

            UpdateLocalRemainingValues();
            UpdateLocalBankerOffer();
            
        }

        private void ShowInvalidCase(int caseNumber)
        {
            statusLabel.Text = "Invalid case " + caseNumber.ToString("D2") + " was already chosen";

            caseBoxes[caseNumber].BackColor = Color.Red;
            caseBoxes[caseNumber].ForeColor = Color.White;
            
        }

        private void RedrawBoard()
        {
            for (int i = 0; i < 16; i++)
            {
                if (caseOpened[i])
                {
                    caseBoxes[i].BackColor = Color.Gray;
                    caseBoxes[i].ForeColor = Color.White;
                    continue;
                }

                if (i == previewCase)
                {
                    caseBoxes[i].BackColor = Color.Gold;
                    caseBoxes[i].ForeColor = Color.Black;
                }
                else
                {
                    caseBoxes[i].BackColor = Color.RoyalBlue;
                    caseBoxes[i].ForeColor = Color.White;
                }
            }
            
        }

        private void UpdateLocalRemainingValues()
        {
            int sum = 0;
            int count = 0;

            for (int i = 0; i < 16; i++)
            {
                if (!caseOpened[i])
                {
                    sum += caseValues[i];
                    count++;
                }
            }

            remainingTotal = sum;

            if (count == 0)
                remainingAverage = 0;
            else
                remainingAverage = sum / count;

            remainingTotalLabel.Text = "Remaining Total: $" + remainingTotal.ToString("N0", CultureInfo.InvariantCulture);
            remainingAverageLabel.Text = "Remaining Average: $" + remainingAverage.ToString("N0", CultureInfo.InvariantCulture);
        }

        private void UpdateLocalBankerOffer()
        {
            int openedCount = 0;

            for (int i = 0; i < 16; i++)
            {
                if (caseOpened[i])
                    openedCount++;
            }

            int riskPercent;

            if (openedCount < 4)
                riskPercent = 45;
            else if (openedCount < 8)
                riskPercent = 65;
            else if (openedCount < 12)
                riskPercent = 80;
            else
                riskPercent = 95;

            bankerOffer = (remainingAverage * riskPercent) / 100;

            offerLabel.Text = "Banker Offer: $" + bankerOffer.ToString("N0", CultureInfo.InvariantCulture);
        }

        private void DisableGameButtonsAfterDeal()
        {
            previewButton.Enabled = false;
            previewButton.ForeColor = Color.White;
            previewButton.BackColor = Color.DimGray;
            previewButton.UseVisualStyleBackColor = false;

            confirmButton.Enabled = false;
            confirmButton.ForeColor = Color.White;
            confirmButton.BackColor = Color.DimGray;
            confirmButton.UseVisualStyleBackColor = false;

            dealButton.Enabled = false;
            dealButton.ForeColor = Color.White;
            dealButton.BackColor = Color.DarkGreen;
            dealButton.UseVisualStyleBackColor = false;

            noDealButton.Enabled = false;
            noDealButton.ForeColor = Color.White;
            noDealButton.BackColor = Color.DarkRed;
            noDealButton.UseVisualStyleBackColor = false;
        }

        private void ResetBoard()
        {
            previewCase = -1;
            selectedCase = -1;
            bankerOffer = 0;
            remainingTotal = 0;
            remainingAverage = 0;

            previewLabel.Text = "Preview: --";
            selectedLabel.Text = "Selected: --";
            openedValueLabel.Text = "Opened Value: --";

            for (int i = 0; i < 16; i++)
            {
                caseOpened[i] = false;

                caseBoxes[i].BackColor = Color.RoyalBlue;
                caseBoxes[i].ForeColor = Color.White;

                moneyLabels[i].BackColor = Color.DarkBlue;
                moneyLabels[i].ForeColor = Color.White;
            }

            previewButton.Enabled = true;
            previewButton.ForeColor = Color.White;
            previewButton.BackColor = Color.DimGray;
            previewButton.UseVisualStyleBackColor = false;

            confirmButton.Enabled = true;
            confirmButton.ForeColor = Color.White;
            confirmButton.BackColor = Color.DimGray;
            confirmButton.UseVisualStyleBackColor = false;

            dealButton.Enabled = true;
            dealButton.ForeColor = Color.White;
            dealButton.BackColor = Color.DarkGreen;
            dealButton.UseVisualStyleBackColor = false;

            noDealButton.Enabled = true;
            noDealButton.ForeColor = Color.White;
            noDealButton.BackColor = Color.DarkRed;
            noDealButton.UseVisualStyleBackColor = false;

            resetButton.Enabled = true;
            resetButton.ForeColor = Color.White;
            resetButton.BackColor = Color.DimGray;
            resetButton.UseVisualStyleBackColor = false;

            UpdateLocalRemainingValues();
            UpdateLocalBankerOffer();

            statusLabel.Text = "UI ready. Waiting for FPGA messages.";
            
        }
    }
}