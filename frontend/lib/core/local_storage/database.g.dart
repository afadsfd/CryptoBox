// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ExchangeAccountsTable extends ExchangeAccounts
    with TableInfo<$ExchangeAccountsTable, ExchangeAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exchangeNameMeta =
      const VerificationMeta('exchangeName');
  @override
  late final GeneratedColumn<String> exchangeName = GeneratedColumn<String>(
      'exchange_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _encryptedApiKeyMeta =
      const VerificationMeta('encryptedApiKey');
  @override
  late final GeneratedColumn<String> encryptedApiKey = GeneratedColumn<String>(
      'encrypted_api_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedSecretMeta =
      const VerificationMeta('encryptedSecret');
  @override
  late final GeneratedColumn<String> encryptedSecret = GeneratedColumn<String>(
      'encrypted_secret', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedPassphraseMeta =
      const VerificationMeta('encryptedPassphrase');
  @override
  late final GeneratedColumn<String> encryptedPassphrase =
      GeneratedColumn<String>('encrypted_passphrase', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        exchangeName,
        label,
        encryptedApiKey,
        encryptedSecret,
        encryptedPassphrase,
        isActive,
        lastSyncAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<ExchangeAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exchange_name')) {
      context.handle(
          _exchangeNameMeta,
          exchangeName.isAcceptableOrUnknown(
              data['exchange_name']!, _exchangeNameMeta));
    } else if (isInserting) {
      context.missing(_exchangeNameMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('encrypted_api_key')) {
      context.handle(
          _encryptedApiKeyMeta,
          encryptedApiKey.isAcceptableOrUnknown(
              data['encrypted_api_key']!, _encryptedApiKeyMeta));
    } else if (isInserting) {
      context.missing(_encryptedApiKeyMeta);
    }
    if (data.containsKey('encrypted_secret')) {
      context.handle(
          _encryptedSecretMeta,
          encryptedSecret.isAcceptableOrUnknown(
              data['encrypted_secret']!, _encryptedSecretMeta));
    } else if (isInserting) {
      context.missing(_encryptedSecretMeta);
    }
    if (data.containsKey('encrypted_passphrase')) {
      context.handle(
          _encryptedPassphraseMeta,
          encryptedPassphrase.isAcceptableOrUnknown(
              data['encrypted_passphrase']!, _encryptedPassphraseMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      exchangeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exchange_name'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      encryptedApiKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_api_key'])!,
      encryptedSecret: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_secret'])!,
      encryptedPassphrase: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_passphrase']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ExchangeAccountsTable createAlias(String alias) {
    return $ExchangeAccountsTable(attachedDatabase, alias);
  }
}

class ExchangeAccount extends DataClass implements Insertable<ExchangeAccount> {
  final String id;
  final String exchangeName;
  final String label;
  final String encryptedApiKey;
  final String encryptedSecret;
  final String? encryptedPassphrase;
  final bool isActive;
  final DateTime? lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExchangeAccount(
      {required this.id,
      required this.exchangeName,
      required this.label,
      required this.encryptedApiKey,
      required this.encryptedSecret,
      this.encryptedPassphrase,
      required this.isActive,
      this.lastSyncAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exchange_name'] = Variable<String>(exchangeName);
    map['label'] = Variable<String>(label);
    map['encrypted_api_key'] = Variable<String>(encryptedApiKey);
    map['encrypted_secret'] = Variable<String>(encryptedSecret);
    if (!nullToAbsent || encryptedPassphrase != null) {
      map['encrypted_passphrase'] = Variable<String>(encryptedPassphrase);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExchangeAccountsCompanion toCompanion(bool nullToAbsent) {
    return ExchangeAccountsCompanion(
      id: Value(id),
      exchangeName: Value(exchangeName),
      label: Value(label),
      encryptedApiKey: Value(encryptedApiKey),
      encryptedSecret: Value(encryptedSecret),
      encryptedPassphrase: encryptedPassphrase == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptedPassphrase),
      isActive: Value(isActive),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExchangeAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeAccount(
      id: serializer.fromJson<String>(json['id']),
      exchangeName: serializer.fromJson<String>(json['exchangeName']),
      label: serializer.fromJson<String>(json['label']),
      encryptedApiKey: serializer.fromJson<String>(json['encryptedApiKey']),
      encryptedSecret: serializer.fromJson<String>(json['encryptedSecret']),
      encryptedPassphrase:
          serializer.fromJson<String?>(json['encryptedPassphrase']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exchangeName': serializer.toJson<String>(exchangeName),
      'label': serializer.toJson<String>(label),
      'encryptedApiKey': serializer.toJson<String>(encryptedApiKey),
      'encryptedSecret': serializer.toJson<String>(encryptedSecret),
      'encryptedPassphrase': serializer.toJson<String?>(encryptedPassphrase),
      'isActive': serializer.toJson<bool>(isActive),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExchangeAccount copyWith(
          {String? id,
          String? exchangeName,
          String? label,
          String? encryptedApiKey,
          String? encryptedSecret,
          Value<String?> encryptedPassphrase = const Value.absent(),
          bool? isActive,
          Value<DateTime?> lastSyncAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ExchangeAccount(
        id: id ?? this.id,
        exchangeName: exchangeName ?? this.exchangeName,
        label: label ?? this.label,
        encryptedApiKey: encryptedApiKey ?? this.encryptedApiKey,
        encryptedSecret: encryptedSecret ?? this.encryptedSecret,
        encryptedPassphrase: encryptedPassphrase.present
            ? encryptedPassphrase.value
            : this.encryptedPassphrase,
        isActive: isActive ?? this.isActive,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ExchangeAccount copyWithCompanion(ExchangeAccountsCompanion data) {
    return ExchangeAccount(
      id: data.id.present ? data.id.value : this.id,
      exchangeName: data.exchangeName.present
          ? data.exchangeName.value
          : this.exchangeName,
      label: data.label.present ? data.label.value : this.label,
      encryptedApiKey: data.encryptedApiKey.present
          ? data.encryptedApiKey.value
          : this.encryptedApiKey,
      encryptedSecret: data.encryptedSecret.present
          ? data.encryptedSecret.value
          : this.encryptedSecret,
      encryptedPassphrase: data.encryptedPassphrase.present
          ? data.encryptedPassphrase.value
          : this.encryptedPassphrase,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeAccount(')
          ..write('id: $id, ')
          ..write('exchangeName: $exchangeName, ')
          ..write('label: $label, ')
          ..write('encryptedApiKey: $encryptedApiKey, ')
          ..write('encryptedSecret: $encryptedSecret, ')
          ..write('encryptedPassphrase: $encryptedPassphrase, ')
          ..write('isActive: $isActive, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      exchangeName,
      label,
      encryptedApiKey,
      encryptedSecret,
      encryptedPassphrase,
      isActive,
      lastSyncAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeAccount &&
          other.id == this.id &&
          other.exchangeName == this.exchangeName &&
          other.label == this.label &&
          other.encryptedApiKey == this.encryptedApiKey &&
          other.encryptedSecret == this.encryptedSecret &&
          other.encryptedPassphrase == this.encryptedPassphrase &&
          other.isActive == this.isActive &&
          other.lastSyncAt == this.lastSyncAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExchangeAccountsCompanion extends UpdateCompanion<ExchangeAccount> {
  final Value<String> id;
  final Value<String> exchangeName;
  final Value<String> label;
  final Value<String> encryptedApiKey;
  final Value<String> encryptedSecret;
  final Value<String?> encryptedPassphrase;
  final Value<bool> isActive;
  final Value<DateTime?> lastSyncAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExchangeAccountsCompanion({
    this.id = const Value.absent(),
    this.exchangeName = const Value.absent(),
    this.label = const Value.absent(),
    this.encryptedApiKey = const Value.absent(),
    this.encryptedSecret = const Value.absent(),
    this.encryptedPassphrase = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeAccountsCompanion.insert({
    required String id,
    required String exchangeName,
    this.label = const Value.absent(),
    required String encryptedApiKey,
    required String encryptedSecret,
    this.encryptedPassphrase = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        exchangeName = Value(exchangeName),
        encryptedApiKey = Value(encryptedApiKey),
        encryptedSecret = Value(encryptedSecret);
  static Insertable<ExchangeAccount> custom({
    Expression<String>? id,
    Expression<String>? exchangeName,
    Expression<String>? label,
    Expression<String>? encryptedApiKey,
    Expression<String>? encryptedSecret,
    Expression<String>? encryptedPassphrase,
    Expression<bool>? isActive,
    Expression<DateTime>? lastSyncAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exchangeName != null) 'exchange_name': exchangeName,
      if (label != null) 'label': label,
      if (encryptedApiKey != null) 'encrypted_api_key': encryptedApiKey,
      if (encryptedSecret != null) 'encrypted_secret': encryptedSecret,
      if (encryptedPassphrase != null)
        'encrypted_passphrase': encryptedPassphrase,
      if (isActive != null) 'is_active': isActive,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeAccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? exchangeName,
      Value<String>? label,
      Value<String>? encryptedApiKey,
      Value<String>? encryptedSecret,
      Value<String?>? encryptedPassphrase,
      Value<bool>? isActive,
      Value<DateTime?>? lastSyncAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ExchangeAccountsCompanion(
      id: id ?? this.id,
      exchangeName: exchangeName ?? this.exchangeName,
      label: label ?? this.label,
      encryptedApiKey: encryptedApiKey ?? this.encryptedApiKey,
      encryptedSecret: encryptedSecret ?? this.encryptedSecret,
      encryptedPassphrase: encryptedPassphrase ?? this.encryptedPassphrase,
      isActive: isActive ?? this.isActive,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exchangeName.present) {
      map['exchange_name'] = Variable<String>(exchangeName.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (encryptedApiKey.present) {
      map['encrypted_api_key'] = Variable<String>(encryptedApiKey.value);
    }
    if (encryptedSecret.present) {
      map['encrypted_secret'] = Variable<String>(encryptedSecret.value);
    }
    if (encryptedPassphrase.present) {
      map['encrypted_passphrase'] = Variable<String>(encryptedPassphrase.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeAccountsCompanion(')
          ..write('id: $id, ')
          ..write('exchangeName: $exchangeName, ')
          ..write('label: $label, ')
          ..write('encryptedApiKey: $encryptedApiKey, ')
          ..write('encryptedSecret: $encryptedSecret, ')
          ..write('encryptedPassphrase: $encryptedPassphrase, ')
          ..write('isActive: $isActive, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HoldingsTable extends Holdings with TableInfo<$HoldingsTable, Holding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HoldingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exchangeAccountIdMeta =
      const VerificationMeta('exchangeAccountId');
  @override
  late final GeneratedColumn<String> exchangeAccountId =
      GeneratedColumn<String>('exchange_account_id', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES exchange_accounts (id)'));
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _freeMeta = const VerificationMeta('free');
  @override
  late final GeneratedColumn<double> free = GeneratedColumn<double>(
      'free', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<double> locked = GeneratedColumn<double>(
      'locked', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _priceUsdMeta =
      const VerificationMeta('priceUsd');
  @override
  late final GeneratedColumn<double> priceUsd = GeneratedColumn<double>(
      'price_usd', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _valueUsdMeta =
      const VerificationMeta('valueUsd');
  @override
  late final GeneratedColumn<double> valueUsd = GeneratedColumn<double>(
      'value_usd', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('spot'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        exchangeAccountId,
        symbol,
        quantity,
        free,
        locked,
        priceUsd,
        valueUsd,
        source,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holdings';
  @override
  VerificationContext validateIntegrity(Insertable<Holding> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exchange_account_id')) {
      context.handle(
          _exchangeAccountIdMeta,
          exchangeAccountId.isAcceptableOrUnknown(
              data['exchange_account_id']!, _exchangeAccountIdMeta));
    } else if (isInserting) {
      context.missing(_exchangeAccountIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('free')) {
      context.handle(
          _freeMeta, free.isAcceptableOrUnknown(data['free']!, _freeMeta));
    }
    if (data.containsKey('locked')) {
      context.handle(_lockedMeta,
          locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta));
    }
    if (data.containsKey('price_usd')) {
      context.handle(_priceUsdMeta,
          priceUsd.isAcceptableOrUnknown(data['price_usd']!, _priceUsdMeta));
    }
    if (data.containsKey('value_usd')) {
      context.handle(_valueUsdMeta,
          valueUsd.isAcceptableOrUnknown(data['value_usd']!, _valueUsdMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Holding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Holding(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      exchangeAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exchange_account_id'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      free: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}free'])!,
      locked: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}locked'])!,
      priceUsd: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_usd']),
      valueUsd: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value_usd']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HoldingsTable createAlias(String alias) {
    return $HoldingsTable(attachedDatabase, alias);
  }
}

class Holding extends DataClass implements Insertable<Holding> {
  final String id;
  final String exchangeAccountId;
  final String symbol;
  final double quantity;
  final double free;
  final double locked;
  final double? priceUsd;
  final double? valueUsd;

  /// 资金来源：spot / earn / futures
  final String source;
  final DateTime updatedAt;
  const Holding(
      {required this.id,
      required this.exchangeAccountId,
      required this.symbol,
      required this.quantity,
      required this.free,
      required this.locked,
      this.priceUsd,
      this.valueUsd,
      required this.source,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exchange_account_id'] = Variable<String>(exchangeAccountId);
    map['symbol'] = Variable<String>(symbol);
    map['quantity'] = Variable<double>(quantity);
    map['free'] = Variable<double>(free);
    map['locked'] = Variable<double>(locked);
    if (!nullToAbsent || priceUsd != null) {
      map['price_usd'] = Variable<double>(priceUsd);
    }
    if (!nullToAbsent || valueUsd != null) {
      map['value_usd'] = Variable<double>(valueUsd);
    }
    map['source'] = Variable<String>(source);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HoldingsCompanion toCompanion(bool nullToAbsent) {
    return HoldingsCompanion(
      id: Value(id),
      exchangeAccountId: Value(exchangeAccountId),
      symbol: Value(symbol),
      quantity: Value(quantity),
      free: Value(free),
      locked: Value(locked),
      priceUsd: priceUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsd),
      valueUsd: valueUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(valueUsd),
      source: Value(source),
      updatedAt: Value(updatedAt),
    );
  }

  factory Holding.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Holding(
      id: serializer.fromJson<String>(json['id']),
      exchangeAccountId: serializer.fromJson<String>(json['exchangeAccountId']),
      symbol: serializer.fromJson<String>(json['symbol']),
      quantity: serializer.fromJson<double>(json['quantity']),
      free: serializer.fromJson<double>(json['free']),
      locked: serializer.fromJson<double>(json['locked']),
      priceUsd: serializer.fromJson<double?>(json['priceUsd']),
      valueUsd: serializer.fromJson<double?>(json['valueUsd']),
      source: serializer.fromJson<String>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exchangeAccountId': serializer.toJson<String>(exchangeAccountId),
      'symbol': serializer.toJson<String>(symbol),
      'quantity': serializer.toJson<double>(quantity),
      'free': serializer.toJson<double>(free),
      'locked': serializer.toJson<double>(locked),
      'priceUsd': serializer.toJson<double?>(priceUsd),
      'valueUsd': serializer.toJson<double?>(valueUsd),
      'source': serializer.toJson<String>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Holding copyWith(
          {String? id,
          String? exchangeAccountId,
          String? symbol,
          double? quantity,
          double? free,
          double? locked,
          Value<double?> priceUsd = const Value.absent(),
          Value<double?> valueUsd = const Value.absent(),
          String? source,
          DateTime? updatedAt}) =>
      Holding(
        id: id ?? this.id,
        exchangeAccountId: exchangeAccountId ?? this.exchangeAccountId,
        symbol: symbol ?? this.symbol,
        quantity: quantity ?? this.quantity,
        free: free ?? this.free,
        locked: locked ?? this.locked,
        priceUsd: priceUsd.present ? priceUsd.value : this.priceUsd,
        valueUsd: valueUsd.present ? valueUsd.value : this.valueUsd,
        source: source ?? this.source,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Holding copyWithCompanion(HoldingsCompanion data) {
    return Holding(
      id: data.id.present ? data.id.value : this.id,
      exchangeAccountId: data.exchangeAccountId.present
          ? data.exchangeAccountId.value
          : this.exchangeAccountId,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      free: data.free.present ? data.free.value : this.free,
      locked: data.locked.present ? data.locked.value : this.locked,
      priceUsd: data.priceUsd.present ? data.priceUsd.value : this.priceUsd,
      valueUsd: data.valueUsd.present ? data.valueUsd.value : this.valueUsd,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Holding(')
          ..write('id: $id, ')
          ..write('exchangeAccountId: $exchangeAccountId, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('free: $free, ')
          ..write('locked: $locked, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('valueUsd: $valueUsd, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exchangeAccountId, symbol, quantity, free,
      locked, priceUsd, valueUsd, source, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Holding &&
          other.id == this.id &&
          other.exchangeAccountId == this.exchangeAccountId &&
          other.symbol == this.symbol &&
          other.quantity == this.quantity &&
          other.free == this.free &&
          other.locked == this.locked &&
          other.priceUsd == this.priceUsd &&
          other.valueUsd == this.valueUsd &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class HoldingsCompanion extends UpdateCompanion<Holding> {
  final Value<String> id;
  final Value<String> exchangeAccountId;
  final Value<String> symbol;
  final Value<double> quantity;
  final Value<double> free;
  final Value<double> locked;
  final Value<double?> priceUsd;
  final Value<double?> valueUsd;
  final Value<String> source;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HoldingsCompanion({
    this.id = const Value.absent(),
    this.exchangeAccountId = const Value.absent(),
    this.symbol = const Value.absent(),
    this.quantity = const Value.absent(),
    this.free = const Value.absent(),
    this.locked = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.valueUsd = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HoldingsCompanion.insert({
    required String id,
    required String exchangeAccountId,
    required String symbol,
    this.quantity = const Value.absent(),
    this.free = const Value.absent(),
    this.locked = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.valueUsd = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        exchangeAccountId = Value(exchangeAccountId),
        symbol = Value(symbol);
  static Insertable<Holding> custom({
    Expression<String>? id,
    Expression<String>? exchangeAccountId,
    Expression<String>? symbol,
    Expression<double>? quantity,
    Expression<double>? free,
    Expression<double>? locked,
    Expression<double>? priceUsd,
    Expression<double>? valueUsd,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exchangeAccountId != null) 'exchange_account_id': exchangeAccountId,
      if (symbol != null) 'symbol': symbol,
      if (quantity != null) 'quantity': quantity,
      if (free != null) 'free': free,
      if (locked != null) 'locked': locked,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (valueUsd != null) 'value_usd': valueUsd,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HoldingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? exchangeAccountId,
      Value<String>? symbol,
      Value<double>? quantity,
      Value<double>? free,
      Value<double>? locked,
      Value<double?>? priceUsd,
      Value<double?>? valueUsd,
      Value<String>? source,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HoldingsCompanion(
      id: id ?? this.id,
      exchangeAccountId: exchangeAccountId ?? this.exchangeAccountId,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      free: free ?? this.free,
      locked: locked ?? this.locked,
      priceUsd: priceUsd ?? this.priceUsd,
      valueUsd: valueUsd ?? this.valueUsd,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exchangeAccountId.present) {
      map['exchange_account_id'] = Variable<String>(exchangeAccountId.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (free.present) {
      map['free'] = Variable<double>(free.value);
    }
    if (locked.present) {
      map['locked'] = Variable<double>(locked.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<double>(priceUsd.value);
    }
    if (valueUsd.present) {
      map['value_usd'] = Variable<double>(valueUsd.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HoldingsCompanion(')
          ..write('id: $id, ')
          ..write('exchangeAccountId: $exchangeAccountId, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('free: $free, ')
          ..write('locked: $locked, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('valueUsd: $valueUsd, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PortfolioSnapshotsTable extends PortfolioSnapshots
    with TableInfo<$PortfolioSnapshotsTable, PortfolioSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PortfolioSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalValueUsdMeta =
      const VerificationMeta('totalValueUsd');
  @override
  late final GeneratedColumn<double> totalValueUsd = GeneratedColumn<double>(
      'total_value_usd', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _snapshotAtMeta =
      const VerificationMeta('snapshotAt');
  @override
  late final GeneratedColumn<DateTime> snapshotAt = GeneratedColumn<DateTime>(
      'snapshot_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, totalValueUsd, snapshotAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'portfolio_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<PortfolioSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('total_value_usd')) {
      context.handle(
          _totalValueUsdMeta,
          totalValueUsd.isAcceptableOrUnknown(
              data['total_value_usd']!, _totalValueUsdMeta));
    } else if (isInserting) {
      context.missing(_totalValueUsdMeta);
    }
    if (data.containsKey('snapshot_at')) {
      context.handle(
          _snapshotAtMeta,
          snapshotAt.isAcceptableOrUnknown(
              data['snapshot_at']!, _snapshotAtMeta));
    } else if (isInserting) {
      context.missing(_snapshotAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PortfolioSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PortfolioSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      totalValueUsd: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_value_usd'])!,
      snapshotAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}snapshot_at'])!,
    );
  }

  @override
  $PortfolioSnapshotsTable createAlias(String alias) {
    return $PortfolioSnapshotsTable(attachedDatabase, alias);
  }
}

class PortfolioSnapshot extends DataClass
    implements Insertable<PortfolioSnapshot> {
  final String id;
  final double totalValueUsd;
  final DateTime snapshotAt;
  const PortfolioSnapshot(
      {required this.id,
      required this.totalValueUsd,
      required this.snapshotAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['total_value_usd'] = Variable<double>(totalValueUsd);
    map['snapshot_at'] = Variable<DateTime>(snapshotAt);
    return map;
  }

  PortfolioSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PortfolioSnapshotsCompanion(
      id: Value(id),
      totalValueUsd: Value(totalValueUsd),
      snapshotAt: Value(snapshotAt),
    );
  }

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PortfolioSnapshot(
      id: serializer.fromJson<String>(json['id']),
      totalValueUsd: serializer.fromJson<double>(json['totalValueUsd']),
      snapshotAt: serializer.fromJson<DateTime>(json['snapshotAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'totalValueUsd': serializer.toJson<double>(totalValueUsd),
      'snapshotAt': serializer.toJson<DateTime>(snapshotAt),
    };
  }

  PortfolioSnapshot copyWith(
          {String? id, double? totalValueUsd, DateTime? snapshotAt}) =>
      PortfolioSnapshot(
        id: id ?? this.id,
        totalValueUsd: totalValueUsd ?? this.totalValueUsd,
        snapshotAt: snapshotAt ?? this.snapshotAt,
      );
  PortfolioSnapshot copyWithCompanion(PortfolioSnapshotsCompanion data) {
    return PortfolioSnapshot(
      id: data.id.present ? data.id.value : this.id,
      totalValueUsd: data.totalValueUsd.present
          ? data.totalValueUsd.value
          : this.totalValueUsd,
      snapshotAt:
          data.snapshotAt.present ? data.snapshotAt.value : this.snapshotAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioSnapshot(')
          ..write('id: $id, ')
          ..write('totalValueUsd: $totalValueUsd, ')
          ..write('snapshotAt: $snapshotAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, totalValueUsd, snapshotAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PortfolioSnapshot &&
          other.id == this.id &&
          other.totalValueUsd == this.totalValueUsd &&
          other.snapshotAt == this.snapshotAt);
}

class PortfolioSnapshotsCompanion extends UpdateCompanion<PortfolioSnapshot> {
  final Value<String> id;
  final Value<double> totalValueUsd;
  final Value<DateTime> snapshotAt;
  final Value<int> rowid;
  const PortfolioSnapshotsCompanion({
    this.id = const Value.absent(),
    this.totalValueUsd = const Value.absent(),
    this.snapshotAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PortfolioSnapshotsCompanion.insert({
    required String id,
    required double totalValueUsd,
    required DateTime snapshotAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        totalValueUsd = Value(totalValueUsd),
        snapshotAt = Value(snapshotAt);
  static Insertable<PortfolioSnapshot> custom({
    Expression<String>? id,
    Expression<double>? totalValueUsd,
    Expression<DateTime>? snapshotAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalValueUsd != null) 'total_value_usd': totalValueUsd,
      if (snapshotAt != null) 'snapshot_at': snapshotAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PortfolioSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<double>? totalValueUsd,
      Value<DateTime>? snapshotAt,
      Value<int>? rowid}) {
    return PortfolioSnapshotsCompanion(
      id: id ?? this.id,
      totalValueUsd: totalValueUsd ?? this.totalValueUsd,
      snapshotAt: snapshotAt ?? this.snapshotAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (totalValueUsd.present) {
      map['total_value_usd'] = Variable<double>(totalValueUsd.value);
    }
    if (snapshotAt.present) {
      map['snapshot_at'] = Variable<DateTime>(snapshotAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('totalValueUsd: $totalValueUsd, ')
          ..write('snapshotAt: $snapshotAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceCacheTable extends PriceCache
    with TableInfo<$PriceCacheTable, PriceCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceUsdMeta =
      const VerificationMeta('priceUsd');
  @override
  late final GeneratedColumn<double> priceUsd = GeneratedColumn<double>(
      'price_usd', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _change24hMeta =
      const VerificationMeta('change24h');
  @override
  late final GeneratedColumn<double> change24h = GeneratedColumn<double>(
      'change24h', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [symbol, priceUsd, change24h, imageUrl, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PriceCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('price_usd')) {
      context.handle(_priceUsdMeta,
          priceUsd.isAcceptableOrUnknown(data['price_usd']!, _priceUsdMeta));
    } else if (isInserting) {
      context.missing(_priceUsdMeta);
    }
    if (data.containsKey('change24h')) {
      context.handle(_change24hMeta,
          change24h.isAcceptableOrUnknown(data['change24h']!, _change24hMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  PriceCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceCacheData(
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      priceUsd: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_usd'])!,
      change24h: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}change24h'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PriceCacheTable createAlias(String alias) {
    return $PriceCacheTable(attachedDatabase, alias);
  }
}

class PriceCacheData extends DataClass implements Insertable<PriceCacheData> {
  final String symbol;
  final double priceUsd;
  final double change24h;

  /// 币种图标 URL（CoinGecko small image），持久化后 App 重启秒出
  final String? imageUrl;
  final DateTime updatedAt;
  const PriceCacheData(
      {required this.symbol,
      required this.priceUsd,
      required this.change24h,
      this.imageUrl,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['price_usd'] = Variable<double>(priceUsd);
    map['change24h'] = Variable<double>(change24h);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PriceCacheCompanion toCompanion(bool nullToAbsent) {
    return PriceCacheCompanion(
      symbol: Value(symbol),
      priceUsd: Value(priceUsd),
      change24h: Value(change24h),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory PriceCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceCacheData(
      symbol: serializer.fromJson<String>(json['symbol']),
      priceUsd: serializer.fromJson<double>(json['priceUsd']),
      change24h: serializer.fromJson<double>(json['change24h']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'priceUsd': serializer.toJson<double>(priceUsd),
      'change24h': serializer.toJson<double>(change24h),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PriceCacheData copyWith(
          {String? symbol,
          double? priceUsd,
          double? change24h,
          Value<String?> imageUrl = const Value.absent(),
          DateTime? updatedAt}) =>
      PriceCacheData(
        symbol: symbol ?? this.symbol,
        priceUsd: priceUsd ?? this.priceUsd,
        change24h: change24h ?? this.change24h,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PriceCacheData copyWithCompanion(PriceCacheCompanion data) {
    return PriceCacheData(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      priceUsd: data.priceUsd.present ? data.priceUsd.value : this.priceUsd,
      change24h: data.change24h.present ? data.change24h.value : this.change24h,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceCacheData(')
          ..write('symbol: $symbol, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('change24h: $change24h, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(symbol, priceUsd, change24h, imageUrl, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceCacheData &&
          other.symbol == this.symbol &&
          other.priceUsd == this.priceUsd &&
          other.change24h == this.change24h &&
          other.imageUrl == this.imageUrl &&
          other.updatedAt == this.updatedAt);
}

class PriceCacheCompanion extends UpdateCompanion<PriceCacheData> {
  final Value<String> symbol;
  final Value<double> priceUsd;
  final Value<double> change24h;
  final Value<String?> imageUrl;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PriceCacheCompanion({
    this.symbol = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.change24h = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceCacheCompanion.insert({
    required String symbol,
    required double priceUsd,
    this.change24h = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : symbol = Value(symbol),
        priceUsd = Value(priceUsd);
  static Insertable<PriceCacheData> custom({
    Expression<String>? symbol,
    Expression<double>? priceUsd,
    Expression<double>? change24h,
    Expression<String>? imageUrl,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (change24h != null) 'change24h': change24h,
      if (imageUrl != null) 'image_url': imageUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceCacheCompanion copyWith(
      {Value<String>? symbol,
      Value<double>? priceUsd,
      Value<double>? change24h,
      Value<String?>? imageUrl,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PriceCacheCompanion(
      symbol: symbol ?? this.symbol,
      priceUsd: priceUsd ?? this.priceUsd,
      change24h: change24h ?? this.change24h,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<double>(priceUsd.value);
    }
    if (change24h.present) {
      map['change24h'] = Variable<double>(change24h.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('change24h: $change24h, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExchangeAccountsTable exchangeAccounts =
      $ExchangeAccountsTable(this);
  late final $HoldingsTable holdings = $HoldingsTable(this);
  late final $PortfolioSnapshotsTable portfolioSnapshots =
      $PortfolioSnapshotsTable(this);
  late final $PriceCacheTable priceCache = $PriceCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [exchangeAccounts, holdings, portfolioSnapshots, priceCache];
}

typedef $$ExchangeAccountsTableCreateCompanionBuilder
    = ExchangeAccountsCompanion Function({
  required String id,
  required String exchangeName,
  Value<String> label,
  required String encryptedApiKey,
  required String encryptedSecret,
  Value<String?> encryptedPassphrase,
  Value<bool> isActive,
  Value<DateTime?> lastSyncAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ExchangeAccountsTableUpdateCompanionBuilder
    = ExchangeAccountsCompanion Function({
  Value<String> id,
  Value<String> exchangeName,
  Value<String> label,
  Value<String> encryptedApiKey,
  Value<String> encryptedSecret,
  Value<String?> encryptedPassphrase,
  Value<bool> isActive,
  Value<DateTime?> lastSyncAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ExchangeAccountsTableReferences extends BaseReferences<
    _$AppDatabase, $ExchangeAccountsTable, ExchangeAccount> {
  $$ExchangeAccountsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HoldingsTable, List<Holding>> _holdingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.holdings,
          aliasName: $_aliasNameGenerator(
              db.exchangeAccounts.id, db.holdings.exchangeAccountId));

  $$HoldingsTableProcessedTableManager get holdingsRefs {
    final manager = $$HoldingsTableTableManager($_db, $_db.holdings).filter(
        (f) => f.exchangeAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_holdingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExchangeAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeAccountsTable> {
  $$ExchangeAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exchangeName => $composableBuilder(
      column: $table.exchangeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedApiKey => $composableBuilder(
      column: $table.encryptedApiKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedSecret => $composableBuilder(
      column: $table.encryptedSecret,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedPassphrase => $composableBuilder(
      column: $table.encryptedPassphrase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> holdingsRefs(
      Expression<bool> Function($$HoldingsTableFilterComposer f) f) {
    final $$HoldingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.holdings,
        getReferencedColumn: (t) => t.exchangeAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HoldingsTableFilterComposer(
              $db: $db,
              $table: $db.holdings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExchangeAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeAccountsTable> {
  $$ExchangeAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exchangeName => $composableBuilder(
      column: $table.exchangeName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedApiKey => $composableBuilder(
      column: $table.encryptedApiKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedSecret => $composableBuilder(
      column: $table.encryptedSecret,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedPassphrase => $composableBuilder(
      column: $table.encryptedPassphrase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ExchangeAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeAccountsTable> {
  $$ExchangeAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exchangeName => $composableBuilder(
      column: $table.exchangeName, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get encryptedApiKey => $composableBuilder(
      column: $table.encryptedApiKey, builder: (column) => column);

  GeneratedColumn<String> get encryptedSecret => $composableBuilder(
      column: $table.encryptedSecret, builder: (column) => column);

  GeneratedColumn<String> get encryptedPassphrase => $composableBuilder(
      column: $table.encryptedPassphrase, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> holdingsRefs<T extends Object>(
      Expression<T> Function($$HoldingsTableAnnotationComposer a) f) {
    final $$HoldingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.holdings,
        getReferencedColumn: (t) => t.exchangeAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HoldingsTableAnnotationComposer(
              $db: $db,
              $table: $db.holdings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExchangeAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExchangeAccountsTable,
    ExchangeAccount,
    $$ExchangeAccountsTableFilterComposer,
    $$ExchangeAccountsTableOrderingComposer,
    $$ExchangeAccountsTableAnnotationComposer,
    $$ExchangeAccountsTableCreateCompanionBuilder,
    $$ExchangeAccountsTableUpdateCompanionBuilder,
    (ExchangeAccount, $$ExchangeAccountsTableReferences),
    ExchangeAccount,
    PrefetchHooks Function({bool holdingsRefs})> {
  $$ExchangeAccountsTableTableManager(
      _$AppDatabase db, $ExchangeAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> exchangeName = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> encryptedApiKey = const Value.absent(),
            Value<String> encryptedSecret = const Value.absent(),
            Value<String?> encryptedPassphrase = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeAccountsCompanion(
            id: id,
            exchangeName: exchangeName,
            label: label,
            encryptedApiKey: encryptedApiKey,
            encryptedSecret: encryptedSecret,
            encryptedPassphrase: encryptedPassphrase,
            isActive: isActive,
            lastSyncAt: lastSyncAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String exchangeName,
            Value<String> label = const Value.absent(),
            required String encryptedApiKey,
            required String encryptedSecret,
            Value<String?> encryptedPassphrase = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExchangeAccountsCompanion.insert(
            id: id,
            exchangeName: exchangeName,
            label: label,
            encryptedApiKey: encryptedApiKey,
            encryptedSecret: encryptedSecret,
            encryptedPassphrase: encryptedPassphrase,
            isActive: isActive,
            lastSyncAt: lastSyncAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExchangeAccountsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({holdingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (holdingsRefs) db.holdings],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (holdingsRefs)
                    await $_getPrefetchedData<ExchangeAccount,
                            $ExchangeAccountsTable, Holding>(
                        currentTable: table,
                        referencedTable: $$ExchangeAccountsTableReferences
                            ._holdingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExchangeAccountsTableReferences(db, table, p0)
                                .holdingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exchangeAccountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExchangeAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExchangeAccountsTable,
    ExchangeAccount,
    $$ExchangeAccountsTableFilterComposer,
    $$ExchangeAccountsTableOrderingComposer,
    $$ExchangeAccountsTableAnnotationComposer,
    $$ExchangeAccountsTableCreateCompanionBuilder,
    $$ExchangeAccountsTableUpdateCompanionBuilder,
    (ExchangeAccount, $$ExchangeAccountsTableReferences),
    ExchangeAccount,
    PrefetchHooks Function({bool holdingsRefs})>;
typedef $$HoldingsTableCreateCompanionBuilder = HoldingsCompanion Function({
  required String id,
  required String exchangeAccountId,
  required String symbol,
  Value<double> quantity,
  Value<double> free,
  Value<double> locked,
  Value<double?> priceUsd,
  Value<double?> valueUsd,
  Value<String> source,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$HoldingsTableUpdateCompanionBuilder = HoldingsCompanion Function({
  Value<String> id,
  Value<String> exchangeAccountId,
  Value<String> symbol,
  Value<double> quantity,
  Value<double> free,
  Value<double> locked,
  Value<double?> priceUsd,
  Value<double?> valueUsd,
  Value<String> source,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$HoldingsTableReferences
    extends BaseReferences<_$AppDatabase, $HoldingsTable, Holding> {
  $$HoldingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExchangeAccountsTable _exchangeAccountIdTable(_$AppDatabase db) =>
      db.exchangeAccounts.createAlias($_aliasNameGenerator(
          db.holdings.exchangeAccountId, db.exchangeAccounts.id));

  $$ExchangeAccountsTableProcessedTableManager get exchangeAccountId {
    final $_column = $_itemColumn<String>('exchange_account_id')!;

    final manager =
        $$ExchangeAccountsTableTableManager($_db, $_db.exchangeAccounts)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exchangeAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HoldingsTableFilterComposer
    extends Composer<_$AppDatabase, $HoldingsTable> {
  $$HoldingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get free => $composableBuilder(
      column: $table.free, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get locked => $composableBuilder(
      column: $table.locked, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceUsd => $composableBuilder(
      column: $table.priceUsd, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valueUsd => $composableBuilder(
      column: $table.valueUsd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ExchangeAccountsTableFilterComposer get exchangeAccountId {
    final $$ExchangeAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exchangeAccountId,
        referencedTable: $db.exchangeAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExchangeAccountsTableFilterComposer(
              $db: $db,
              $table: $db.exchangeAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HoldingsTableOrderingComposer
    extends Composer<_$AppDatabase, $HoldingsTable> {
  $$HoldingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get free => $composableBuilder(
      column: $table.free, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get locked => $composableBuilder(
      column: $table.locked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceUsd => $composableBuilder(
      column: $table.priceUsd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valueUsd => $composableBuilder(
      column: $table.valueUsd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ExchangeAccountsTableOrderingComposer get exchangeAccountId {
    final $$ExchangeAccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exchangeAccountId,
        referencedTable: $db.exchangeAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExchangeAccountsTableOrderingComposer(
              $db: $db,
              $table: $db.exchangeAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HoldingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HoldingsTable> {
  $$HoldingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get free =>
      $composableBuilder(column: $table.free, builder: (column) => column);

  GeneratedColumn<double> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

  GeneratedColumn<double> get priceUsd =>
      $composableBuilder(column: $table.priceUsd, builder: (column) => column);

  GeneratedColumn<double> get valueUsd =>
      $composableBuilder(column: $table.valueUsd, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ExchangeAccountsTableAnnotationComposer get exchangeAccountId {
    final $$ExchangeAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exchangeAccountId,
        referencedTable: $db.exchangeAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExchangeAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.exchangeAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HoldingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HoldingsTable,
    Holding,
    $$HoldingsTableFilterComposer,
    $$HoldingsTableOrderingComposer,
    $$HoldingsTableAnnotationComposer,
    $$HoldingsTableCreateCompanionBuilder,
    $$HoldingsTableUpdateCompanionBuilder,
    (Holding, $$HoldingsTableReferences),
    Holding,
    PrefetchHooks Function({bool exchangeAccountId})> {
  $$HoldingsTableTableManager(_$AppDatabase db, $HoldingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HoldingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HoldingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HoldingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> exchangeAccountId = const Value.absent(),
            Value<String> symbol = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> free = const Value.absent(),
            Value<double> locked = const Value.absent(),
            Value<double?> priceUsd = const Value.absent(),
            Value<double?> valueUsd = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HoldingsCompanion(
            id: id,
            exchangeAccountId: exchangeAccountId,
            symbol: symbol,
            quantity: quantity,
            free: free,
            locked: locked,
            priceUsd: priceUsd,
            valueUsd: valueUsd,
            source: source,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String exchangeAccountId,
            required String symbol,
            Value<double> quantity = const Value.absent(),
            Value<double> free = const Value.absent(),
            Value<double> locked = const Value.absent(),
            Value<double?> priceUsd = const Value.absent(),
            Value<double?> valueUsd = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HoldingsCompanion.insert(
            id: id,
            exchangeAccountId: exchangeAccountId,
            symbol: symbol,
            quantity: quantity,
            free: free,
            locked: locked,
            priceUsd: priceUsd,
            valueUsd: valueUsd,
            source: source,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$HoldingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({exchangeAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exchangeAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exchangeAccountId,
                    referencedTable:
                        $$HoldingsTableReferences._exchangeAccountIdTable(db),
                    referencedColumn: $$HoldingsTableReferences
                        ._exchangeAccountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HoldingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HoldingsTable,
    Holding,
    $$HoldingsTableFilterComposer,
    $$HoldingsTableOrderingComposer,
    $$HoldingsTableAnnotationComposer,
    $$HoldingsTableCreateCompanionBuilder,
    $$HoldingsTableUpdateCompanionBuilder,
    (Holding, $$HoldingsTableReferences),
    Holding,
    PrefetchHooks Function({bool exchangeAccountId})>;
typedef $$PortfolioSnapshotsTableCreateCompanionBuilder
    = PortfolioSnapshotsCompanion Function({
  required String id,
  required double totalValueUsd,
  required DateTime snapshotAt,
  Value<int> rowid,
});
typedef $$PortfolioSnapshotsTableUpdateCompanionBuilder
    = PortfolioSnapshotsCompanion Function({
  Value<String> id,
  Value<double> totalValueUsd,
  Value<DateTime> snapshotAt,
  Value<int> rowid,
});

class $$PortfolioSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $PortfolioSnapshotsTable> {
  $$PortfolioSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalValueUsd => $composableBuilder(
      column: $table.totalValueUsd, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snapshotAt => $composableBuilder(
      column: $table.snapshotAt, builder: (column) => ColumnFilters(column));
}

class $$PortfolioSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PortfolioSnapshotsTable> {
  $$PortfolioSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalValueUsd => $composableBuilder(
      column: $table.totalValueUsd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snapshotAt => $composableBuilder(
      column: $table.snapshotAt, builder: (column) => ColumnOrderings(column));
}

class $$PortfolioSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PortfolioSnapshotsTable> {
  $$PortfolioSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalValueUsd => $composableBuilder(
      column: $table.totalValueUsd, builder: (column) => column);

  GeneratedColumn<DateTime> get snapshotAt => $composableBuilder(
      column: $table.snapshotAt, builder: (column) => column);
}

class $$PortfolioSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PortfolioSnapshotsTable,
    PortfolioSnapshot,
    $$PortfolioSnapshotsTableFilterComposer,
    $$PortfolioSnapshotsTableOrderingComposer,
    $$PortfolioSnapshotsTableAnnotationComposer,
    $$PortfolioSnapshotsTableCreateCompanionBuilder,
    $$PortfolioSnapshotsTableUpdateCompanionBuilder,
    (
      PortfolioSnapshot,
      BaseReferences<_$AppDatabase, $PortfolioSnapshotsTable, PortfolioSnapshot>
    ),
    PortfolioSnapshot,
    PrefetchHooks Function()> {
  $$PortfolioSnapshotsTableTableManager(
      _$AppDatabase db, $PortfolioSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PortfolioSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PortfolioSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PortfolioSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> totalValueUsd = const Value.absent(),
            Value<DateTime> snapshotAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PortfolioSnapshotsCompanion(
            id: id,
            totalValueUsd: totalValueUsd,
            snapshotAt: snapshotAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double totalValueUsd,
            required DateTime snapshotAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PortfolioSnapshotsCompanion.insert(
            id: id,
            totalValueUsd: totalValueUsd,
            snapshotAt: snapshotAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PortfolioSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PortfolioSnapshotsTable,
    PortfolioSnapshot,
    $$PortfolioSnapshotsTableFilterComposer,
    $$PortfolioSnapshotsTableOrderingComposer,
    $$PortfolioSnapshotsTableAnnotationComposer,
    $$PortfolioSnapshotsTableCreateCompanionBuilder,
    $$PortfolioSnapshotsTableUpdateCompanionBuilder,
    (
      PortfolioSnapshot,
      BaseReferences<_$AppDatabase, $PortfolioSnapshotsTable, PortfolioSnapshot>
    ),
    PortfolioSnapshot,
    PrefetchHooks Function()>;
typedef $$PriceCacheTableCreateCompanionBuilder = PriceCacheCompanion Function({
  required String symbol,
  required double priceUsd,
  Value<double> change24h,
  Value<String?> imageUrl,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$PriceCacheTableUpdateCompanionBuilder = PriceCacheCompanion Function({
  Value<String> symbol,
  Value<double> priceUsd,
  Value<double> change24h,
  Value<String?> imageUrl,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PriceCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PriceCacheTable> {
  $$PriceCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceUsd => $composableBuilder(
      column: $table.priceUsd, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get change24h => $composableBuilder(
      column: $table.change24h, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PriceCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceCacheTable> {
  $$PriceCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceUsd => $composableBuilder(
      column: $table.priceUsd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get change24h => $composableBuilder(
      column: $table.change24h, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PriceCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceCacheTable> {
  $$PriceCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get priceUsd =>
      $composableBuilder(column: $table.priceUsd, builder: (column) => column);

  GeneratedColumn<double> get change24h =>
      $composableBuilder(column: $table.change24h, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PriceCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PriceCacheTable,
    PriceCacheData,
    $$PriceCacheTableFilterComposer,
    $$PriceCacheTableOrderingComposer,
    $$PriceCacheTableAnnotationComposer,
    $$PriceCacheTableCreateCompanionBuilder,
    $$PriceCacheTableUpdateCompanionBuilder,
    (
      PriceCacheData,
      BaseReferences<_$AppDatabase, $PriceCacheTable, PriceCacheData>
    ),
    PriceCacheData,
    PrefetchHooks Function()> {
  $$PriceCacheTableTableManager(_$AppDatabase db, $PriceCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> symbol = const Value.absent(),
            Value<double> priceUsd = const Value.absent(),
            Value<double> change24h = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PriceCacheCompanion(
            symbol: symbol,
            priceUsd: priceUsd,
            change24h: change24h,
            imageUrl: imageUrl,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String symbol,
            required double priceUsd,
            Value<double> change24h = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PriceCacheCompanion.insert(
            symbol: symbol,
            priceUsd: priceUsd,
            change24h: change24h,
            imageUrl: imageUrl,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PriceCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PriceCacheTable,
    PriceCacheData,
    $$PriceCacheTableFilterComposer,
    $$PriceCacheTableOrderingComposer,
    $$PriceCacheTableAnnotationComposer,
    $$PriceCacheTableCreateCompanionBuilder,
    $$PriceCacheTableUpdateCompanionBuilder,
    (
      PriceCacheData,
      BaseReferences<_$AppDatabase, $PriceCacheTable, PriceCacheData>
    ),
    PriceCacheData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExchangeAccountsTableTableManager get exchangeAccounts =>
      $$ExchangeAccountsTableTableManager(_db, _db.exchangeAccounts);
  $$HoldingsTableTableManager get holdings =>
      $$HoldingsTableTableManager(_db, _db.holdings);
  $$PortfolioSnapshotsTableTableManager get portfolioSnapshots =>
      $$PortfolioSnapshotsTableTableManager(_db, _db.portfolioSnapshots);
  $$PriceCacheTableTableManager get priceCache =>
      $$PriceCacheTableTableManager(_db, _db.priceCache);
}
