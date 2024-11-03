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

    image =
      raw
      |> Base.decode64!()
      |> Evision.imdecode(Evision.Constant.cv_IMREAD_COLOR())

    {_dims, [height, width]} = Evision.Mat.size(image)
    affine = Evision.getRotationMatrix2D({width / 2, height / 2}, 30, 1)

    processed_image =
      image
      # 四角形の描画
      |> Evision.rectangle(
        # 左上座標{x, y}
        {50, 30},
        # 右下座標{x, y}
        {80, 70},
        # 色{R, G, B}
        {0, 0, 255},
        # 線の太さ
        thickness: 5,
        # 線の引き方（角がギザギザになる）
        lineType: Evision.Constant.cv_LINE_4()
      )
      # 回転
      |> Evision.warpAffine(affine, {width, height})
      # 文字列の描画
      |> Evision.putText(
        # 文字列
        "Hello",
        # 文字の左下座標{x, y}
        {100, 100},
        # フォント種類
        Evision.Constant.cv_FONT_HERSHEY_SIMPLEX(),
        # フォントサイズ
        1,
        # 文字色
        {0, 0, 255},
        # 文字太さ
        thickness: 2
      )
      |> then(&Evision.imencode(".jpg", &1))

    {:noreply, assign(socket, processed_image: processed_image)}
  end
end
