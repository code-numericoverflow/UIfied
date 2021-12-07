using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading;
using System.Text;
using System.IO;
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
		private string UploadFolder;

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
		public void PublishFileUpload(string uploadFolder, string actionUrl = "/files/upload")
        {
			this.UploadFolder = uploadFolder;
			UI.Publish("/files", this.CreateFileUploadElement(), true);
			UI.PublishCustomResponse(actionUrl, HandleUpload);
		}
		void HandleUpload(HttpListenerContext context, CancellationToken token)
		{

			SaveFile(context.Request.ContentEncoding, GetBoundary(context.Request.ContentType), context.Request.InputStream);

			context.Response.StatusCode = 200;
			context.Response.ContentType = "text/html";
			using (StreamWriter writer = new StreamWriter(context.Response.OutputStream, Encoding.UTF8))
				writer.WriteLine("File Uploaded");

			context.Response.Close();
		}

		private static String GetBoundary(String ctype)
		{
			return "--" + ctype.Split(';')[1].Split('=')[1];
		}

		private static void SaveFile(Encoding enc, String boundary, Stream input)
		{
			Byte[] boundaryBytes = enc.GetBytes(boundary);
			Int32 boundaryLen = boundaryBytes.Length;

			Byte[] buffer = new Byte[1024];
			Int32 len = input.Read(buffer, 0, 1024);
			Int32 startPos = -1;

			var inputText = System.Text.UTF8Encoding.UTF8.GetString(buffer);
			var fileNameBeginPos = inputText.IndexOf("filename=") + "filename=".Length;
			var fileNameLen = inputText.Substring(fileNameBeginPos).IndexOf('\n') - 1;
			var fileName = inputText.Substring(fileNameBeginPos, fileNameLen).Replace("\"", "");

			using (FileStream output = new FileStream(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) + System.IO.Path.DirectorySeparatorChar + fileName, FileMode.Create, FileAccess.Write))
			{

				// Find start boundary
				while (true)
				{
					if (len == 0)
					{
						throw new Exception("Start Boundaray Not Found");
					}

					startPos = IndexOf(buffer, len, boundaryBytes);
					if (startPos >= 0)
					{
						break;
					}
					else
					{
						Array.Copy(buffer, len - boundaryLen, buffer, 0, boundaryLen);
						len = input.Read(buffer, boundaryLen, 1024 - boundaryLen);
					}
				}

				// Skip four lines (Boundary, Content-Disposition, Content-Type, and a blank)
				for (Int32 i = 0; i < 4; i++)
				{
					while (true)
					{
						if (len == 0)
						{
							throw new Exception("Preamble not Found.");
						}

						startPos = Array.IndexOf(buffer, enc.GetBytes("\n")[0], startPos);
						if (startPos >= 0)
						{
							startPos++;
							break;
						}
						else
						{
							len = input.Read(buffer, 0, 1024);
						}
					}
				}

				Array.Copy(buffer, startPos, buffer, 0, len - startPos);
				len = len - startPos;

				while (true)
				{
					Int32 endPos = IndexOf(buffer, len, boundaryBytes);
					if (endPos >= 0)
					{
						if (endPos > 0) output.Write(buffer, 0, endPos - 2);
						break;
					}
					else if (len <= boundaryLen)
					{
						throw new Exception("End Boundaray Not Found");
					}
					else
					{
						output.Write(buffer, 0, len - boundaryLen);
						Array.Copy(buffer, len - boundaryLen, buffer, 0, boundaryLen);
						len = input.Read(buffer, boundaryLen, 1024 - boundaryLen) + boundaryLen;
					}
				}
			}
		}

		private static Int32 IndexOf(Byte[] buffer, Int32 len, Byte[] boundaryBytes)
		{
			for (Int32 i = 0; i <= len - boundaryBytes.Length; i++)
			{
				Boolean match = true;
				for (Int32 j = 0; j < boundaryBytes.Length && match; j++)
				{
					match = buffer[i + j] == boundaryBytes[j];
				}

				if (match)
				{
					return i;
				}
			}

			return -1;
		}
		public Element CreateFileUploadElement(string actionUrl = "/files/upload")
		{
			var heading = new Heading("Upload Files");
			var subtitle = new Paragraph("Upload files to the app");

			var uploadForm = new Form();
			uploadForm.Action = actionUrl;
			uploadForm.Method = "POST";
			uploadForm.EncodingType = "multipart/form-data";
			uploadForm.AppendChild(new Input(InputType.File) { Name = "file" });
			uploadForm.AppendChild(new Input(InputType.Submit) { Value = "Upload" });

			var app = new Div();
			app.AppendChild(heading);
			app.AppendChild(subtitle);
			app.AppendChild(uploadForm);

			return app;
		}
	}
}
