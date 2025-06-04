class Api::V1::FaultEventsController < ApplicationController
  def create
    render json: { message: "Fault event received" }, status: :accepted
  end
end
