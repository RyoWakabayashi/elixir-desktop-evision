defmodule ElixirDesktopEvision.Store do
  use Agent

  require Logger

  def start_link(_opts) do
    # priv ディレクトリー配下から取得する
    priv_path = List.to_string(:code.priv_dir(:elixir_desktop_evision))

    cfg_path = priv_path <> "/models/yolov3.cfg"
    weights_path = priv_path <> "/models/yolov3.weights"
    labels_path = priv_path <> "/models/labels.txt"

    Logger.info("Load labels from #{labels_path}")

    model =
      weights_path
      |> Evision.DNN.DetectionModel.detectionModel(config: cfg_path)
      |> Evision.DNN.DetectionModel.setInputParams(
        scale: 1.0 / 255.0,
        size: {608, 608},
        swapRB: true,
        crop: false
      )

    label_list =
      labels_path
      |> File.stream!()
      |> Enum.map(&String.trim/1)

    # Agent に入れておく
    Agent.start_link(
      fn ->
        %{
          model: model,
          label_list: label_list
        }
      end,
      name: __MODULE__
    )
  end

  # 使用時に Agent から取り出す
  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end
end
