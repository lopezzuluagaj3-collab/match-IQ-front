import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/user.dart';
import '../bloc/admin_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String? _roleFilter;   // null | 'Candidate' | 'Company' | 'Admin'
  bool? _activeFilter;   // null | true | false
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter({String? role, bool? active}) {
    setState(() {
      _roleFilter = role;
      _activeFilter = active;
    });
    context.read<AdminCubit>().loadUsers(
      role: role,
      isActive: active,
    );
  }

  List<AdminUser> _filtered(List<AdminUser> users) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) =>
        u.fullName.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        (u.profileName?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.adminUsers,
      role: UserRole.admin,
      child: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.onTertiaryContainer,
            ));
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          final visible = _filtered(state.users);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gestión de Usuarios',
                              style: AppTextStyles.headlineLg),
                          const SizedBox(height: 4),
                          Text(
                            '${state.users.length} usuario${state.users.length == 1 ? '' : 's'}',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateAdminDialog(context),
                      icon: const Icon(Symbols.person_add, size: 18),
                      label: const Text('Nuevo Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.onTertiaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filters + search
                AppCard(
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o email...',
                            hintStyle: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.outline),
                            prefixIcon: const Icon(Symbols.search,
                                size: 18, color: AppColors.outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.secondary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Role filter
                      _FilterChip(
                        label: 'Todos',
                        active: _roleFilter == null && _activeFilter == null,
                        onTap: () => _applyFilter(),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Candidatos',
                        active: _roleFilter == 'Candidate',
                        onTap: () => _applyFilter(role: 'Candidate'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Empresas',
                        active: _roleFilter == 'Company',
                        onTap: () => _applyFilter(role: 'Company'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Admins',
                        active: _roleFilter == 'Admin',
                        onTap: () => _applyFilter(role: 'Admin'),
                      ),
                      const SizedBox(width: 16),
                      _FilterChip(
                        label: 'Inactivos',
                        active: _activeFilter == false,
                        onTap: () => _applyFilter(active: false),
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Users list
                if (state.isLoadingUsers)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(
                          color: AppColors.onTertiaryContainer),
                    ),
                  )
                else if (visible.isEmpty)
                  _EmptyState()
                else
                  AppCard(
                    child: Column(
                      children: visible
                          .asMap()
                          .entries
                          .map((e) => _UserRow(
                                user: e.value,
                                isLast: e.key == visible.length - 1,
                                isSaving: state.isSaving,
                                onToggle: () => context
                                    .read<AdminCubit>()
                                    .toggleUserStatus(e.value.id),
                                onDelete: () =>
                                    _confirmDelete(context, e.value),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar usuario', style: AppTextStyles.headlineMd),
        content: Text(
          '¿Confirmas que deseas eliminar a "${user.displayName}"?\n\nEsta acción es irreversible y eliminará en cascada todos sus datos.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCreateAdminDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<AdminCubit>(),
        child: _CreateAdminDialog(
          formKey: formKey,
          fullNameCtrl: fullNameCtrl,
          emailCtrl: emailCtrl,
          cedulaCtrl: cedulaCtrl,
          passCtrl: passCtrl,
          confirmCtrl: confirmCtrl,
        ),
      ),
    );
  }
}

// ─── User row ─────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isLast,
    required this.isSaving,
    required this.onToggle,
    required this.onDelete,
  });
  final AdminUser user;
  final bool isLast;
  final bool isSaving;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  Color get _roleColor => switch (user.role) {
        'Admin' => AppColors.error,
        'Company' => AppColors.onTertiaryContainer,
        _ => AppColors.secondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35))),
            ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: _roleColor.withValues(alpha: 0.12),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: AppTextStyles.labelBold
                  .copyWith(color: _roleColor, fontSize: 15),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.displayName,
                        style: AppTextStyles.labelBold.copyWith(fontSize: 14)),
                    const SizedBox(width: 8),
                    _RoleBadge(role: user.role, color: _roleColor),
                    if (!user.isActive) ...[
                      const SizedBox(width: 6),
                      _Badge(
                          label: 'Inactivo', color: AppColors.error),
                    ],
                    if (!user.emailVerified) ...[
                      const SizedBox(width: 6),
                      _Badge(
                          label: 'Sin verificar',
                          color: const Color(0xFFF59E0B)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
                Text('Cédula: ${user.cedula}  ·  Desde ${_formatDate(user.createdAt)}',
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.outline, fontSize: 11)),
              ],
            ),
          ),

          // Actions — no actions on Admin accounts
          if (user.role != 'Admin') ...[
            Tooltip(
              message: user.isActive ? 'Desactivar cuenta' : 'Activar cuenta',
              child: InkWell(
                onTap: isSaving ? null : onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (user.isActive ? AppColors.error : AppColors.onTertiaryContainer)
                        .withValues(alpha: 0.08),
                    border: Border.all(
                        color: (user.isActive
                                ? AppColors.error
                                : AppColors.onTertiaryContainer)
                            .withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isActive
                            ? Symbols.block
                            : Symbols.check_circle,
                        size: 13,
                        color: user.isActive
                            ? AppColors.error
                            : AppColors.onTertiaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        user.isActive ? 'Desactivar' : 'Activar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user.isActive
                                ? AppColors.error
                                : AppColors.onTertiaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Eliminar usuario',
              child: InkWell(
                onTap: isSaving ? null : onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Symbols.delete_outline,
                      size: 15,
                      color: AppColors.error.withValues(alpha: 0.8)),
                ),
              ),
            ),
          ] else
            Tooltip(
              message: 'Las cuentas Admin no pueden modificarse desde aquí',
              child: Icon(Symbols.shield,
                  size: 18,
                  color: AppColors.outline.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

// ─── Create admin dialog ──────────────────────────────────────────────────────

class _CreateAdminDialog extends StatefulWidget {
  const _CreateAdminDialog({
    required this.formKey,
    required this.fullNameCtrl,
    required this.emailCtrl,
    required this.cedulaCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController cedulaCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;

  @override
  State<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<_CreateAdminDialog> {
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: widget.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Symbols.admin_panel_settings,
                        color: AppColors.onTertiaryContainer, size: 22),
                    const SizedBox(width: 10),
                    Text('Crear Administrador',
                        style: AppTextStyles.headlineMd),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Symbols.close,
                          color: AppColors.outline, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _Field(ctrl: widget.fullNameCtrl, label: 'Nombre completo',
                    icon: Symbols.person,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Requerido' : null),
                const SizedBox(height: 12),
                _Field(ctrl: widget.emailCtrl, label: 'Email',
                    icon: Symbols.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.contains('@') ?? false)
                        ? null
                        : 'Email inválido'),
                const SizedBox(height: 12),
                _Field(ctrl: widget.cedulaCtrl, label: 'Cédula',
                    icon: Symbols.badge,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Requerido' : null),
                const SizedBox(height: 12),
                _Field(
                    ctrl: widget.passCtrl,
                    label: 'Contraseña',
                    icon: Symbols.lock,
                    obscure: !_showPass,
                    suffix: IconButton(
                      icon: Icon(
                          _showPass ? Symbols.visibility_off : Symbols.visibility,
                          size: 18, color: AppColors.outline),
                      onPressed: () =>
                          setState(() => _showPass = !_showPass),
                    ),
                    validator: (v) => (v?.length ?? 0) >= 8
                        ? null
                        : 'Mínimo 8 caracteres'),
                const SizedBox(height: 12),
                _Field(
                    ctrl: widget.confirmCtrl,
                    label: 'Confirmar contraseña',
                    icon: Symbols.lock_reset,
                    obscure: !_showConfirm,
                    suffix: IconButton(
                      icon: Icon(
                          _showConfirm
                              ? Symbols.visibility_off
                              : Symbols.visibility,
                          size: 18, color: AppColors.outline),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                    validator: (v) => v == widget.passCtrl.text
                        ? null
                        : 'Las contraseñas no coinciden'),
                const SizedBox(height: 24),

                BlocBuilder<AdminCubit, AdminState>(
                  builder: (context, state) => Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar',
                            style: AppTextStyles.labelBold.copyWith(
                                color: AppColors.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: state.isSaving
                            ? null
                            : () async {
                                if (!widget.formKey.currentState!.validate()) {
                                  return;
                                }
                                final ok = await context
                                    .read<AdminCubit>()
                                    .createAdminUser(
                                      fullName: widget.fullNameCtrl.text.trim(),
                                      email: widget.emailCtrl.text.trim(),
                                      cedula: widget.cedulaCtrl.text.trim(),
                                      password: widget.passCtrl.text,
                                      confirmPassword: widget.confirmCtrl.text,
                                    );
                                if (ok && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onTertiaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: state.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Crear Administrador'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
              color: active ? c : AppColors.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: AppTextStyles.labelSm.copyWith(
                color: active ? c : AppColors.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.color});
  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(role,
          style: AppTextStyles.labelSm
              .copyWith(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm
              .copyWith(color: color, fontSize: 10)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Symbols.person_search,
                size: 48, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text('No se encontraron usuarios.',
                style: AppTextStyles.bodyLg
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
