defmodule ElixirDesktopEvisionWeb.CameraLive do
  use ElixirDesktopEvisionWeb, :live_view

  @impl true
  def mount(_args, _session, socket) do
    socket
    |> assign(processed_image: nil)
    |> then(&{:ok, &1})
  end

  # 写真撮影時の処理
  @impl true
  def handle_event("take", %{"image" => base64}, socket) do
    "data:image/jpeg;base64," <> raw = base64

    {_results, processed_image} =
      raw
      |> Base.decode64!()
      |> ElixirDesktopEvision.Worker.detect()

    {:noreply, assign(socket, processed_image: processed_image)}
  end
end
