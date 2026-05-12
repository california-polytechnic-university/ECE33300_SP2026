using DealOrNoDealUINEW;
using System.Windows.Forms;
using System;

class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new Form1());

    }
}