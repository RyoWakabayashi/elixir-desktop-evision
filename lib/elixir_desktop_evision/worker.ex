defmodule ElixirDesktopEvision.Worker do
  use Agent

  require Logger

  alias ElixirDesktopEvision.Store

  def detect(binary) do
    mat = to_mat(binary)

    predictions = predict(mat)

    drawed =
      Evision.imencode(".png", draw_predictions(mat, predictions))
      |> IO.iodata_to_binary()

    {predictions, drawed}
  end

  def measure(function) do
    {time, result} = :timer.tc(function)
    IO.puts("Time: #{time}ms")
    result
  end

  def to_mat(binary) do
    Evision.imdecode(binary, Evision.Constant.cv_IMREAD_COLOR())
  end

  def predict(img) do
    label_list = Store.get(:label_list)

    Store.get(:model)
    |> Evision.DNN.DetectionModel.detect(img, confThreshold: 0.8, nmsThreshold: 0.7)
    |> then(fn {class_ids, scores, boxes} ->
      Enum.zip_with([class_ids, scores, boxes], fn [class_id, score, box] ->
        %{
          box: box,
          score: Float.round(score, 2),
          class: Enum.at(label_list, class_id)
        }
      end)
    end)
    |> IO.inspect(label: "Predictions")
  end

  def draw_predictions(mat, predictions) do
    predictions
    |> Enum.reduce(mat, fn prediction, drawed_mat ->
      {left, top, width, height} = prediction.box

      drawed_mat
      |> Evision.rectangle(
        {left, top},
        {left + width, top + height},
        {255, 0, 0},
        thickness: 4
      )
      |> Evision.putText(
        prediction.class,
        {left + 6, top + 26},
        Evision.Constant.cv_FONT_HERSHEY_SIMPLEX(),
        0.8,
        {0, 0, 255},
        thickness: 2
      )
    end)
  end
end
