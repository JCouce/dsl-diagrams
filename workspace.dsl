workspace "Sistema de Flags sobre Filings" "Versión inicial C1–C3 (contexto, contenedores, componentes)" {

  model {
    
    /********************
     * PERSONAS / ACTORES (C1)
     ********************/
    analista = person "Analista HITL" "Revisa y valida flags; aporta feedback para mejorar reglas y glosarios." {
      tags "A"
    }

    comite = person "Comité de Gobernanza" "Define políticas, umbrales y aprueba cambios estructurales de reglas/modelos." {
      tags "A"
    }

    auditor = person "Auditor Externo" "Consulta flags históricos, trazabilidad y evidencias para auditoría." {
      tags "A"
    }

    /************************
     * SISTEMAS EXTERNOS (EXT) (C1)
     ************************/
    sec = softwareSystem "SEC/EDGAR" "Fuente de filings (8-K, 10-Q, 10-K, 6-K)." {
      tags "Ext"
    }

    crm = softwareSystem "CRM / Portal Interno" "Consume flags, scores y explicaciones para flujos de negocio." {
      tags "Ext"
    }

    /******************************
     * SISTEMA PRINCIPAL (CORE/C4)
     ******************************/
    sistema = softwareSystem "Sistema de Flags sobre Filings" "Pipeline para ingestión, análisis, extracción de señales (flags), scoring, ticketing HITL y gobierno del conocimiento." {
      tags "Core"
      properties {
        version "v1.0"
      }

      /************************
       * CONTENEDORES (C2)
       ************************/
      ingesta = container "Ingesta" "Captura filings por feed y fetch incremental (CIK/fecha)." "Servicio" {
        tags "S"
      }

      parsing = container "Parsing / OCR" "Convierte HTML/PDF a texto estructurado; OCR si no hay texto embebido." "Servicio" {
        tags "S"
      }

      normalizacion = container "Normalización" "Limpieza, canonicalización, separación por secciones y extracción de tablas." "Servicio" {
        tags "S"
      }

      motor = container "Motor de Extracción" "Extracción híbrida (reglas deterministas + ML/LLM) y resolución de conflictos." "Servicio" {
        tags "S"
        properties {
          version "v1.0"
        }

        /*********************************
         * COMPONENTES (C3) – Motor de Extracción
         *********************************/
        capa_det = component "Capa determinista" "Diccionarios, expresiones y reglas por sección; extracción de evidencias fuertes." "Lógica" {
          tags "S"
        }

        capa_ml = component "Capa ML / LLM" "Clasificadores/LLM para señales débiles y lenguaje ofuscado." "Modelo" {
          tags "S"
        }

        resolutor = component "Resolutor de conflictos" "Prioriza capas; aplica políticas de abstención y umbrales." "Lógica" {
          tags "S"
        }

        dsl = component "Evaluador de reglas (DSL)" "Interpreta reglas versionadas (YAML/JSON); operadores: umbrales, match semántico, conteo de evidencias, antigüedad." "Lógica" {
          tags "S"
        }

        calibrador = component "Calibrador / conjunto oro" "Mide precisión/recall por flag y sector; recalibra umbrales periódicamente." "Proceso" {
          tags "S"
        }

        gestor_tickets = component "Gestor de tickets automáticos" "Crea tickets para baja confianza, contradicciones o novedad lingüística." "Orquestación" {
          tags "S"
        }
      }

      scoring = container "Scoring & Explicaciones" "Calcula score de confianza por flag y genera explicación mínima (snippets + localización)." "Servicio" {
        tags "S"
      }

      ticketing = container "Ticketing / HITL" "Crea y gestiona tickets automáticos; integra revisión humana y feedback-loop." "Servicio" {
        tags "S"
      }

      backoffice = container "Backoffice" "Consola web para revisión, búsqueda, filtros y acciones (confirmar/descartar/abstener/ajustar regla)." "Web UI" {
        tags "A UI"
      }

      api = container "API de Consulta / Export" "Expone flags, scores, explicaciones y export (CSV/Parquet); webhooks para integraciones." "Servicio" {
        tags "S"
      }

      observabilidad = container "Observabilidad" "Métricas, alarmas, muestreo ciego, detector de drift lingüístico." "Servicio" {
        tags "S"
      }

      datalake = container "Data Lake" "Almacén bruto de originales, textos, tablas y metadatos." "Storage" {
        tags "Data"
      }

      bdr = container "Base Relacional" "Estados de flags, histórico, tickets, métricas y trazabilidad." "Database" {
        tags "Data"
      }

      vector = container "Índice Vectorial" "Embeddings y búsqueda semántica (recall)." "Database" {
        tags "Data"
      }

      cola = container "Event Bus / Cola" "Desacopla etapas; gestiona eventos, reintentos idempotentes y cuarentenas." "Message Broker" {
        tags "Infra"
      }
    }

    /*********************************
     * RELACIONES (C1/C2)
     *********************************/
    sec -> ingesta "Publica filings (feed / fetch incremental)" "HTTPS"
    ingesta -> cola "Publica eventos de nuevo filing" "evento:new_filing"

    ingesta -> datalake "Escribe originales y metadatos"
    parsing -> datalake "Lee originales" 
    parsing -> normalizacion "Entrega texto estructurado / tablas"
    normalizacion -> datalake "Guarda textos limpios y secciones"

    normalizacion -> motor "Envía secciones y entidades normalizadas"
    motor -> vector "Consulta/actualiza embeddings"
    motor -> bdr "Escribe flags preliminares / evidencias"
    motor -> datalake "Guarda artefactos intermedios (features/snippets)"

    motor -> scoring "Entrega señales y contexto para scoring"
    scoring -> bdr "Escribe score y explicación"

    scoring -> ticketing "Dispara ticket si baja confianza/contradicción/novedad"
    ticketing -> bdr "Actualiza estado de ticket"

    backoffice -> ticketing "Gestiona tickets y decisiones (HITL)" "HTTPS"
    backoffice -> bdr "Consulta histórico, evidencias y trazabilidad" "SQL/HTTPS"

    ticketing -> motor "Feedback para ajuste de reglas/glosario (vía cola)"
    ticketing -> observabilidad "Eventos de calidad / métricas"

    observabilidad -> bdr "Guarda métricas y auditoría"

    api -> bdr "Lee resultados consolidados"
    api -> datalake "Export a CSV/Parquet"

    crm -> api "Consume flags, scores, explicaciones" "HTTPS"

    analista -> backoffice "Revisa y decide sobre tickets" "HTTPS"
    comite -> backoffice "Aprueba cambios de reglas/modelos" "HTTPS"
    auditor -> api "Consulta resultados y auditoría" "HTTPS"

    /*********************************
     * RELACIONES (C3)
     *********************************/
    normalizacion -> dsl "Entrega features/slots por sección"
    dsl -> capa_det "Evalúa reglas deterministas"
    dsl -> capa_ml "Invoca modelos para señales débiles"

    capa_det -> resolutor "Propone evidencias/flags"
    capa_ml -> resolutor "Propone evidencias/flags con score"

    resolutor -> scoring "Entrega evidencias consolidadas"

    dsl -> vector "Consulta similitud / contexto"
    capa_ml -> datalake "Lee/Escribe artefactos de entrenamiento"
    calibrador -> bdr "Registra métricas de validación"
    gestor_tickets -> ticketing "Emite ticket con contexto y severidad"
  }

  views {

    /*******************
     * C1 – CONTEXTO
     *******************/
    systemContext sistema "c1-contexto" "Diagrama de contexto del Sistema de Flags sobre Filings" {
      include *
      autoLayout lr
    }

    /*******************
     * C2 – CONTENEDORES
     *******************/
    container sistema "c2-contenedores" "Diagrama de contenedores del Sistema de Flags sobre Filings" {
      include *
      autoLayout lr
    }

    /********************************************
     * C3 – COMPONENTES (Motor de Extracción)
     ********************************************/
    component motor "c3-motor-extraccion" "Componentes internos del motor de extracción y relaciones clave" {
      include *
      autoLayout lr
    }
  }
}
