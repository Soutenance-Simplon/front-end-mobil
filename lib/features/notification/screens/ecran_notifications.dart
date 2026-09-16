import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';

class EcranNotifications extends ConsumerWidget {
  const EcranNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: notifState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
                : notifications.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune notification pour le moment.",
                          style: TextStyle(color: Color(0xFF8E95A5), fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          final estLue = notif.lue;

                          IconData iconData;
                          Color iconColor;

                          switch (notif.typeNotification) {
                            case 'RAPPEL_RDV':
                              iconData = Icons.videocam_outlined;
                              iconColor = const Color(0xFF00A884);
                              break;
                            case 'PAIEMENT':
                              iconData = Icons.account_balance_wallet_outlined;
                              iconColor = const Color(0xFF00A884);
                              break;
                            case 'RAPPEL_TRAITEMENT':
                              iconData = Icons.medication_outlined;
                              iconColor = const Color(0xFFFF9F65);
                              break;
                            default:
                              iconData = Icons.notifications_none_outlined;
                              iconColor = const Color(0xFF5A607F);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: estLue ? Colors.white : const Color(0xFFE6F7F3).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: estLue ? const Color(0xFFE5E9F2) : const Color(0xFF00A884).withOpacity(0.4),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData, color: iconColor, size: 22),
                              ),
                              title: Text(
                                notif.titre,
                                style: TextStyle(
                                  fontWeight: estLue ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF2D3142),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.corps,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${notif.dateEnvoi.day}/${notif.dateEnvoi.month} à ${notif.dateEnvoi.hour.toString().padLeft(2, '0')}:${notif.dateEnvoi.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                                  ),
                                ],
                              ),
                              onTap: () {
                                ref.read(notificationProvider.notifier).marquerCommeLue(notif.id);
                                if (notif.lienRedirection != null) {
                                  context.push(notif.lienRedirection!);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
