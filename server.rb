# server.rb
require 'active_support/time'
require 'sinatra'
require 'sinatra/cross_origin'
require "sinatra/namespace"
require 'mongoid'


configure do
  enable :cross_origin
end



# DB Setup
Mongoid.load! "mongoid.config"

# Models
class Ocorrencia  
  include Mongoid::Document
  field :titulo, type: String
  field :caminho_foto, type: String
  field :endereco, type: String
  field :bairro, type: String
  field :telefone, type: String
  field :email, type: String
  field :descricao, type: String
  field :data, type: String

  index({ ocorrencia: 'text' })
  # index({ isbn:1 }, { unique: true, name: "isbn_index" })

  scope :ocorrencia, -> (ocorrencia) { where(ocorrencia: /^#{ocorrencia}/) }
  scope :data, -> (data) { where(data: data) }
end

# Serializers
class OcorrenciaSerializer  
  def initialize(ocorrencia)
    @ocorrencia = ocorrencia
  end

  def as_json(*)
    data = {
      id: @ocorrencia.id.to_s,
      titulo: @ocorrencia.titulo,
      data: @ocorrencia.data,
      telefone: @ocorrencia.telefone,
      caminho_foto: @ocorrencia.caminho_foto,
      endereco: @ocorrencia.endereco,
      data: @ocorrencia.data,
      bairro: @ocorrencia.bairro,
      email: @ocorrencia.email,
      descricao: @ocorrencia.descricao,

    }
    data[:errors] = @ocorrencia.errors if @ocorrencia.errors.any?
    data
  end
end


# Endpoints
namespace '/api/v1' do
  
  ocorrencias = Ocorrencia.all

  before do
    content_type 'application/json'
    if request.request_method == 'OPTIONS'
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Methods"] = "*"

      halt 200
    end
  end


  helpers do
    def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
    end
  end

  def ocorrencia
      @ocorrencia ||= Ocorrencia.where(id: params[:id]).first
  end

  def halt_if_not_found!
      halt(404, { message:'Ocorrência não encontrada'}.to_json) unless ocorrencia
  end

  def serialize(ocorrencia)
      OcorrenciaSerializer.new(ocorrencia).to_json
  end


  get '/ocorrencias' do

   [:ocorrencia, :data].each do |filter|
      ocorrencias = ocorrencias.send(filter, params[filter]) if params[filter]
    end

    # We just change this from books.to_json to the following
    ocorrencias.map { |ocorrencia| OcorrenciaSerializer.new(ocorrencia) }.to_json
  end

  get '/ocorrencias/:id' do |id|
    halt_if_not_found!
    serialize(ocorrencia)
  end

  post '/ocorrencias' do
    ocorrencia = Ocorrencia.new(json_params)
    halt 422 unless ocorrencia.save

    # response.headers['Location'] = "#{base_url}/api/v1/ocorrencias/#{ocorrencia.id}"
    # status 201
  end

  patch '/ocorrencias/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(ocorrencia) unless ocorrencia.update_attributes(json_params)
    serialize(ocorrencia)
  end

  delete '/ocorrencias/:id' do |id|
    ocorrencia.destroy if ocorrencia
    status 204
  end

  delete '/ocorrencias/apagar_tuto' do
    ocorrencias = Ocorrencia.all
    ocorrencias.each do |o|
      o.destroy if o
    end

    
    status 204
  end

  

end  
