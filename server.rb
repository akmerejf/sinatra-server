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
  field :notificacao, type: String
  field :doenca, type: String
  field :data_ocorrencia, type: String
  field :uf, type: String
  field :municipio, type: String
  field :codigo_ibge, type: String
  field :fonte, type: String
  field :codigo_fonte, type: String
  field :data_sintoma, type: String
  field :nome_paciente, type: String
  field :nascimento_paciente, type: String
  field :idade_paciente, type: String
  field :sexo_paciente, type: String
  field :gestante, type: String
  field :cor_paciente, type: String
  field :escolaridade, type: String
  field :cartao_sus, type: String
  field :mae_paciente, type: String
  field :uf_paciente, type: String
  field :codigo_ibge_paciente, type: String
  field :distrito_paciente, type: String
  field :bairro_paciente, type: String
  field :logradouro_paciente, type: String
  field :codigo_paciente, type: String
  field :numero_casa_paciente, type: String

  index({ doenca: 'text' })
  # index({ isbn:1 }, { unique: true, name: "isbn_index" })

  scope :doenca, -> (doenca) { where(doenca: /^#{doenca}/) }
  scope :data_ocorrencia, -> (data_ocorrencia) { where(data_ocorrencia: data_ocorrencia) }
end

# Serializers
class OcorrenciaSerializer  
  def initialize(ocorrencia)
    @ocorrencia = ocorrencia
  end

  def as_json(*)
    data = {
      id:@ocorrencia.id.to_s,
      doenca:@ocorrencia.doenca,
      data_ocorrencia:@ocorrencia.data_ocorrencia,
    }
    data[:errors] = @ocorrencia.errors if@ocorrencia.errors.any?
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

   [:doenca, :data_ocorrencia].each do |filter|
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
    halt 422, serialize(ocorrencia) unless ocorrencia.save

    response.headers['Location'] = "#{base_url}/api/v1/ocorrencias/#{ocorrencia.id}"
    status 201
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
