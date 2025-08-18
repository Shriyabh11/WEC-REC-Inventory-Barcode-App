import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String email;

  const UserEntity({
    required this.id,
    required this.email,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'],
      email: map['email'],
    );
  }

  @override
  List<Object?> get props => [id, email];
}
