const supportEmailAddress = 'support@eblo.id';

final supportTelegramChannelUri = Uri.https('t.me', '/ebloid_upd');
final supportAdministratorChatUri = Uri.parse('https://t.me/ebloid_upd?direct');
final legalSourceUri = Uri.https('eblo.id', '/');

const legalRevisionLabel = 'Сводка по редакции сайта от 9 февраля 2026 года';

bool isAllowedSupportDestination(Uri uri) =>
    uri == supportTelegramChannelUri || uri == supportAdministratorChatUri;
