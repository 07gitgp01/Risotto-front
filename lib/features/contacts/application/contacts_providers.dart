import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/application/auth_controller.dart';
import '../data/contacts_models.dart';
import '../data/contacts_repository.dart';
import 'vcard.dart';

class MyQrCodeController extends AsyncNotifier<QrCode> {
  @override
  Future<QrCode> build() => ref.read(contactsRepositoryProvider).getQrCode();

  Future<void> rotate() async {
    state = AsyncData(
      await ref.read(contactsRepositoryProvider).rotateQrCode(),
    );
  }
}

final myQrCodeProvider =
    AsyncNotifierProvider.autoDispose<MyQrCodeController, QrCode>(
      MyQrCodeController.new,
    );

final myCardProvider = FutureProvider.autoDispose<ContactCard>(
  (ref) => ref.watch(contactsRepositoryProvider).getOwnCard(),
);

class SavedContactsController extends AsyncNotifier<List<SavedContact>> {
  ContactsRepository get _repository => ref.read(contactsRepositoryProvider);

  @override
  Future<List<SavedContact>> build() async {
    // Another account must never see the previous user's contacts.
    if (ref.watch(authControllerProvider) is! Authenticated) {
      return const [];
    }
    return _repository.list();
  }

  Future<void> refresh() async {
    state = AsyncData(await _repository.list());
  }

  Future<void> updateNote(String contactId, String? note) async {
    await _repository.updateNote(contactId, note);
    final normalized = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    state = AsyncData([
      for (final contact in state.value ?? <SavedContact>[])
        contact.card.userId == contactId
            ? contact.withNote(normalized)
            : contact,
    ]);
  }

  Future<void> remove(String contactId) async {
    await _repository.remove(contactId);
    state = AsyncData([
      for (final contact in state.value ?? <SavedContact>[])
        if (contact.card.userId != contactId) contact,
    ]);
  }
}

final savedContactsProvider =
    AsyncNotifierProvider<SavedContactsController, List<SavedContact>>(
      SavedContactsController.new,
    );

/// Hands a contact card to the system share sheet as a vCard file.
abstract interface class CardSharer {
  Future<void> share(ContactCard card, {Rect? origin});
}

class SystemCardSharer implements CardSharer {
  @override
  Future<void> share(ContactCard card, {Rect? origin}) async {
    final bytes = utf8.encode(buildVCard(card));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'text/vcard',
            name: vCardFileName(card),
          ),
        ],
        fileNameOverrides: [vCardFileName(card)],
        subject: card.fullName,
        sharePositionOrigin: origin,
      ),
    );
  }
}

final cardSharerProvider = Provider<CardSharer>((ref) => SystemCardSharer());
