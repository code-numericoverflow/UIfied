using Ooui;

namespace OouiWrapper
{
    public class OouiWrapper
    {
        public Element Frame;
        private int Port;
        private string Path;
        public delegate void OnPublishHandler();
        public event OnPublishHandler OnPublish;

        public OouiWrapper(int port = 8187, string path = "/frame")
        {
            this.Port = port;
            this.Path = path;
            this.Frame = new Label { Text = "Press refresh button" };
        }
        public void Publish()
        {
            UI.Port = this.Port;
            UI.Publish(this.Path, MakeElement);
        }
        public Element MakeElement()
        {
            var b = this.MakeFrame();
            UI.Publish(this.Path, MakeElement);
            return b;
        }
        public Element MakeFrame()
        {
            this.OnPublish.Invoke();
            return this.Frame;
        }
    }
}
