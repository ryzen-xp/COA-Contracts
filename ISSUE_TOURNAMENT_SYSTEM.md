# 🏆 Sistema de Torneos PvP - Implementación Completa

## 📋 Descripción del Issue

Implementar un sistema completo de torneos PvP multijugador para el juego "Citizen of Arcanis" utilizando el framework Dojo. El sistema debe permitir la creación, gestión y participación en torneos con un máximo de 100 jugadores por torneo.

## 🎯 Objetivos Principales

- [ ] Crear estructuras de datos para torneos PvP
- [ ] Implementar sistema de registro de jugadores
- [ ] Desarrollar gestión de partidas y brackets
- [ ] Crear sistema de distribución de premios
- [ ] Implementar eventos y notificaciones
- [ ] Crear tests completos del sistema

## 🏗️ Arquitectura del Sistema

### Estructuras de Datos Principales

#### 1. Tournament (Modelo Principal)
```cairo
#[dojo::model]
pub struct Tournament {
    #[key]
    pub id: u64,
    pub name: felt252,
    pub description: felt252,
    pub status: TournamentStatus,
    pub tournament_type: TournamentType,
    pub max_players: u32,        // Máximo 100
    pub current_players: u32,
    pub entry_fee: u256,
    pub total_prize_pool: u256,
    pub prize_distribution: PrizeDistribution,
    pub registration_start_time: u64,
    pub registration_end_time: u64,
    pub tournament_start_time: u64,
    pub tournament_end_time: u64,
    pub created_by: ContractAddress,
    pub created_at: u64,
    pub updated_at: u64,
    pub min_level_requirement: u256,
    pub max_level_requirement: u256,
    pub is_public: bool,
    pub allow_spectators: bool,
    pub current_round: u32,
    pub total_rounds: u32,
}
```

#### 2. TournamentParticipant
```cairo
#[dojo::model]
pub struct TournamentParticipant {
    #[key]
    pub tournament_id: u64,
    #[key]
    pub player_address: ContractAddress,
    pub player_data: TournamentPlayer,
}
```

#### 3. TournamentMatch
```cairo
#[dojo::model]
pub struct TournamentMatch {
    #[key]
    pub tournament_id: u64,
    #[key]
    pub match_id: u64,
    pub match_data: MatchResult,
}
```

#### 4. TournamentWinner
```cairo
#[dojo::model]
pub struct TournamentWinner {
    #[key]
    pub tournament_id: u64,
    #[key]
    pub position: u32,
    pub player_address: ContractAddress,
    pub prize_amount: u256,
    pub claimed: bool,
}
```

## 🔧 Funcionalidades a Implementar

### 1. Gestión de Torneos

#### Crear Torneo
- [ ] Validar parámetros de entrada (nombre, descripción, cuota, máximo jugadores)
- [ ] Establecer fechas de registro y torneo
- [ ] Configurar distribución de premios
- [ ] Emitir evento `TournamentCreated`

#### Iniciar Torneo
- [ ] Verificar que el torneo esté en estado de registro
- [ ] Validar número mínimo de jugadores (2)
- [ ] Calcular brackets según el tipo de torneo
- [ ] Cambiar estado a `InProgress`
- [ ] Emitir evento `TournamentStarted`

#### Finalizar Torneo
- [ ] Procesar resultados finales
- [ ] Calcular premios según distribución
- [ ] Cambiar estado a `Completed`
- [ ] Emitir evento `TournamentCompleted`

### 2. Registro de Jugadores

#### Registrar Jugador
- [ ] Verificar que el torneo esté en estado de registro
- [ ] Validar que no esté lleno (máximo 100)
- [ ] Verificar que el jugador no esté ya registrado
- [ ] Validar cuota de entrada
- [ ] Transferir cuota al pool de premios
- [ ] Emitir evento `PlayerRegistered`

#### Desregistrar Jugador
- [ ] Permitir desregistro antes del inicio del torneo
- [ ] Devolver cuota de entrada
- [ ] Actualizar contadores

### 3. Gestión de Partidas

#### Crear Partida
- [ ] Generar ID único de partida
- [ ] Asignar jugadores según bracket
- [ ] Establecer ronda y horario

#### Procesar Resultado de Partida
- [ ] Validar que la partida esté en progreso
- [ ] Registrar HP restante de ambos jugadores
- [ ] Determinar ganador
- [ ] Actualizar estadísticas de jugadores
- [ ] Emitir evento `MatchCompleted`

### 4. Sistema de Premios

#### Calcular Premios
- [ ] Aplicar distribución configurada
- [ ] Calcular montos según porcentajes
- [ ] Crear registros de ganadores

#### Reclamar Premio
- [ ] Verificar que el jugador sea ganador
- [ ] Validar que no haya sido reclamado
- [ ] Transferir premio al jugador
- [ ] Marcar como reclamado
- [ ] Emitir evento `PrizeClaimed`

## 📁 Archivos a Crear/Modificar

### Nuevos Archivos
- [ ] `src/models/tournament.cairo` - Estructuras de datos de torneos
- [ ] `src/systems/tournament.cairo` - Lógica de negocio de torneos
- [ ] `src/interfaces/tournament.cairo` - Interfaces del sistema
- [ ] `test/tournament_test.cairo` - Tests del sistema

### Archivos a Modificar
- [ ] `src/lib.cairo` - Agregar módulos de torneo
- [ ] `src/models/core.cairo` - Agregar referencias si es necesario

## 🧪 Tests Requeridos

### Tests Unitarios
- [ ] Creación de torneos con diferentes configuraciones
- [ ] Registro y desregistro de jugadores
- [ ] Validaciones de límites y restricciones
- [ ] Cálculo de premios y distribución
- [ ] Gestión de estados de torneo

### Tests de Integración
- [ ] Flujo completo de torneo (creación → registro → partidas → finalización)
- [ ] Manejo de errores y casos edge
- [ ] Interacción con sistema de jugadores existente
- [ ] Gestión de premios y reclamaciones

### Tests de Stress
- [ ] Torneo con 100 jugadores
- [ ] Múltiples torneos simultáneos
- [ ] Manejo de timeouts y cancelaciones

## 🔒 Validaciones y Seguridad

### Validaciones de Entrada
- [ ] Nombre y descripción no vacíos
- [ ] Cuota de entrada mínima (100 créditos)
- [ ] Máximo 100 jugadores
- [ ] Fechas válidas y coherentes
- [ ] Niveles de jugador dentro del rango

### Validaciones de Estado
- [ ] Solo jugadores registrados pueden participar
- [ ] Solo torneos en progreso pueden tener partidas
- [ ] Solo ganadores pueden reclamar premios
- [ ] Solo creador puede cancelar torneo

### Validaciones de Negocio
- [ ] Mínimo 2 jugadores para iniciar
- [ ] Número de jugadores debe ser potencia de 2 para eliminación simple
- [ ] Premios deben sumar 100% de distribución
- [ ] Solo jugadores vivos pueden ganar partidas

## 📊 Eventos a Implementar

### Eventos de Torneo
- [ ] `TournamentCreated` - Torneo creado
- [ ] `TournamentStarted` - Torneo iniciado
- [ ] `TournamentCompleted` - Torneo finalizado
- [ ] `TournamentCancelled` - Torneo cancelado

### Eventos de Jugador
- [ ] `PlayerRegistered` - Jugador registrado
- [ ] `PlayerUnregistered` - Jugador desregistrado
- [ ] `PlayerEliminated` - Jugador eliminado

### Eventos de Partida
- [ ] `MatchCreated` - Partida creada
- [ ] `MatchCompleted` - Partida completada
- [ ] `MatchCancelled` - Partida cancelada

### Eventos de Premios
- [ ] `PrizeDistributed` - Premios distribuidos
- [ ] `PrizeClaimed` - Premio reclamado

## 🎮 Tipos de Torneo Soportados

### 1. Eliminación Simple (Single Elimination)
- [ ] Bracket de eliminación directa
- [ ] Ganador avanza, perdedor eliminado
- [ ] Ideal para 2^n jugadores

### 2. Eliminación Doble (Double Elimination)
- [ ] Bracket principal + bracket de consolación
- [ ] Segunda oportunidad para perdedores
- [ ] Más partidas, más emocionante

### 3. Round Robin
- [ ] Todos contra todos
- [ ] Clasificación por puntos
- [ ] Ideal para torneos pequeños

### 4. Swiss
- [ ] Emparejamiento por puntuación
- [ ] Múltiples rondas
- [ ] Equilibrio entre competitividad y participación

## 🔧 Configuración y Constantes

### Límites del Sistema
```cairo
const MAX_TOURNAMENT_PLAYERS: u32 = 100;
const MIN_TOURNAMENT_PLAYERS: u32 = 2;
const DEFAULT_REGISTRATION_DURATION: u64 = 86400; // 24 horas
const DEFAULT_TOURNAMENT_DURATION: u64 = 3600;    // 1 hora
const MIN_ENTRY_FEE: u256 = 100;                  // 100 créditos
```

### Distribución de Premios por Defecto
```cairo
const DEFAULT_FIRST_PLACE: u32 = 50;   // 50%
const DEFAULT_SECOND_PLACE: u32 = 25;  // 25%
const DEFAULT_THIRD_PLACE: u32 = 15;   // 15%
const DEFAULT_FOURTH_PLACE: u32 = 10;  // 10%
```

## 📈 Métricas y Analytics

### Métricas de Torneo
- [ ] Número total de torneos creados
- [ ] Tasa de participación (registrados vs máximo)
- [ ] Tiempo promedio de duración
- [ ] Distribución de premios por torneo

### Métricas de Jugador
- [ ] Torneos ganados por jugador
- [ ] Premios totales ganados
- [ ] Tasa de victoria en partidas
- [ ] Participación en torneos

## 🚀 Criterios de Aceptación

### Funcionalidad Básica
- [ ] Se puede crear un torneo con todos los parámetros requeridos
- [ ] Los jugadores pueden registrarse y pagar la cuota
- [ ] El torneo inicia automáticamente cuando se alcanza el mínimo de jugadores
- [ ] Las partidas se procesan correctamente
- [ ] Los premios se distribuyen según la configuración

### Integración
- [ ] El sistema se integra correctamente con el modelo de Player existente
- [ ] Los eventos se emiten correctamente
- [ ] El sistema de créditos funciona para cuotas y premios
- [ ] Los niveles de jugador se validan correctamente

### Rendimiento
- [ ] El sistema maneja 100 jugadores sin problemas
- [ ] Las operaciones críticas se completan en tiempo razonable
- [ ] El gas utilizado está optimizado

### Seguridad
- [ ] Solo usuarios autorizados pueden crear torneos
- [ ] Los premios solo pueden ser reclamados por ganadores
- [ ] Las validaciones previenen exploits comunes

## 📝 Notas de Implementación

### Consideraciones Técnicas
- Usar el patrón de eventos de Dojo para notificaciones
- Implementar validaciones robustas en cada función
- Optimizar el uso de storage para minimizar costos de gas
- Usar enums para estados y tipos de torneo

### Integración con Sistema Existente
- Conectar con el sistema de Player para validar niveles
- Usar el sistema de créditos existente para cuotas y premios
- Integrar con el sistema de combate para resultados de partidas
- Mantener consistencia con la arquitectura Dojo existente

### Escalabilidad
- Diseñar para soportar múltiples torneos simultáneos
- Considerar futuras expansiones (torneos por facción, torneos especiales)
- Mantener flexibilidad para nuevos tipos de torneo

## 🎯 Prioridades de Desarrollo

### Fase 1 (MVP)
1. Estructuras de datos básicas
2. Creación y registro de torneos
3. Sistema de partidas simple
4. Distribución básica de premios

### Fase 2 (Funcionalidad Completa)
1. Múltiples tipos de torneo
2. Sistema de brackets avanzado
3. Analytics y métricas
4. Optimizaciones de rendimiento

### Fase 3 (Características Avanzadas)
1. Torneos por facción
2. Torneos especiales con reglas únicas
3. Sistema de rankings
4. Integración con marketplace

---

**Asignado a:** [Desarrollador]
**Prioridad:** Alta
**Estimación:** 2-3 sprints
**Dependencias:** Sistema de Player, Sistema de Créditos
**Labels:** `feature`, `tournament`, `pvp`, `dojo` 