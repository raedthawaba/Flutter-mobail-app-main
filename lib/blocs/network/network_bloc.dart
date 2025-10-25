import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repositories/api_repository.dart';
import '../services/database_service.dart';

// Events
abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object> get props => [];
}

class CheckNetworkConnection extends NetworkEvent {}

class EnableOnlineMode extends NetworkEvent {}

class EnableOfflineMode extends NetworkEvent {}

class SyncLocalData extends NetworkEvent {}

// States
abstract class NetworkState extends Equatable {
  const NetworkState();

  @override
  List<Object> get props => [];
}

class NetworkInitial extends NetworkState {}

class NetworkLoading extends NetworkState {}

class NetworkOnline extends NetworkState {
  final bool isSyncing;
  
  const NetworkOnline({this.isSyncing = false});
  
  @override
  List<Object> get props => [isSyncing];
}

class NetworkOffline extends NetworkState {}

class NetworkError extends NetworkState {
  final String message;
  
  const NetworkError(this.message);
  
  @override
  List<Object> get props => [message];
}

class NetworkSyncComplete extends NetworkState {
  final int syncedItems;
  
  const NetworkSyncComplete(this.syncedItems);
  
  @override
  List<Object> get props => [syncedItems];
}

// BLoC
class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final ApiRepository _apiRepository;
  final DatabaseService _databaseService;
  
  NetworkBloc({
    required ApiRepository apiRepository,
    required DatabaseService databaseService,
  })  : _apiRepository = apiRepository,
        _databaseService = databaseService,
        super(NetworkInitial()) {
    
    on<CheckNetworkConnection>(_onCheckNetworkConnection);
    on<EnableOnlineMode>(_onEnableOnlineMode);
    on<EnableOfflineMode>(_onEnableOfflineMode);
    on<SyncLocalData>(_onSyncLocalData);
    
    // Check connection on initialization
    add(CheckNetworkConnection());
  }
  
  Future<void> _onCheckNetworkConnection(
    CheckNetworkConnection event,
    Emitter<NetworkState> emit,
  ) async {
    emit(NetworkLoading());
    
    try {
      final isConnected = await _apiRepository.checkServerHealth();
      
      if (isConnected) {
        emit(const NetworkOnline());
      } else {
        emit(NetworkOffline());
      }
    } catch (e) {
      emit(NetworkOffline());
    }
  }
  
  Future<void> _onEnableOnlineMode(
    EnableOnlineMode event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final isConnected = await _apiRepository.checkServerHealth();
      
      if (isConnected) {
        emit(const NetworkOnline());
        // Auto-sync when going online
        add(SyncLocalData());
      } else {
        emit(const NetworkError('لا يمكن الاتصال بالخادم'));
      }
    } catch (e) {
      emit(NetworkError('خطأ في الاتصال: $e'));
    }
  }
  
  Future<void> _onEnableOfflineMode(
    EnableOfflineMode event,
    Emitter<NetworkState> emit,
  ) async {
    emit(NetworkOffline());
  }
  
  Future<void> _onSyncLocalData(
    SyncLocalData event,
    Emitter<NetworkState> emit,
  ) async {
    if (state is! NetworkOnline) {
      emit(const NetworkError('يجب أن تكون متصلاً بالإنترنت للمزامنة'));
      return;
    }
    
    emit(const NetworkOnline(isSyncing: true));
    
    try {
      int syncedItems = 0;
      
      // Sync martyrs with status 'pending' or 'draft'
      final localMartyrs = await _databaseService.getAllMartyrs();
      for (final martyr in localMartyrs) {
        if (martyr.status == 'pending' || martyr.status == 'draft') {
          try {
            await _apiRepository.createMartyr(martyr);
            
            // Update local record as synced
            final updatedMartyr = martyr.copyWith(
              status: 'pending', // Server will handle approval
              updatedAt: DateTime.now(),
            );
            await _databaseService.updateMartyr(updatedMartyr);
            syncedItems++;
          } catch (e) {
            print('Failed to sync martyr ${martyr.id}: $e');
          }
        }
      }
      
      // Sync injured
      final localInjured = await _databaseService.getAllInjured();
      for (final injured in localInjured) {
        if (injured.status == 'pending' || injured.status == 'draft') {
          try {
            await _apiRepository.createInjured(injured);
            
            final updatedInjured = injured.copyWith(
              status: 'pending',
              updatedAt: DateTime.now(),
            );
            await _databaseService.updateInjured(updatedInjured);
            syncedItems++;
          } catch (e) {
            print('Failed to sync injured ${injured.id}: $e');
          }
        }
      }
      
      // Sync prisoners
      final localPrisoners = await _databaseService.getAllPrisoners();
      for (final prisoner in localPrisoners) {
        if (prisoner.status == 'pending' || prisoner.status == 'draft') {
          try {
            await _apiRepository.createPrisoner(prisoner);
            
            final updatedPrisoner = prisoner.copyWith(
              status: 'pending',
              updatedAt: DateTime.now(),
            );
            await _databaseService.updatePrisoner(updatedPrisoner);
            syncedItems++;
          } catch (e) {
            print('Failed to sync prisoner ${prisoner.id}: $e');
          }
        }
      }
      
      emit(NetworkSyncComplete(syncedItems));
      
      // Return to online state after sync
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          emit(const NetworkOnline());
        }
      });
      
    } catch (e) {
      emit(NetworkError('فشل في المزامنة: $e'));
    }
  }
  
  // Utility methods
  bool get isOnline => state is NetworkOnline;
  bool get isOffline => state is NetworkOffline;
  bool get isSyncing => state is NetworkOnline && (state as NetworkOnline).isSyncing;
}