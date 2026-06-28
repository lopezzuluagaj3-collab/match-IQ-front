import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/user.dart';
import '../bloc/candidate_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';

class CandidateProfilePage extends StatefulWidget {
  const CandidateProfilePage({super.key});

  @override
  State<CandidateProfilePage> createState() => _CandidateProfilePageState();
}

class _CandidateProfilePageState extends State<CandidateProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<CandidateCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSidebar(
      currentRoute: AppRoutes.candidateProfile,
      role: UserRole.candidate,
      child: BlocBuilder<CandidateCubit, CandidateState>(
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: CircularProgressIndicator(color: AppColors.onTertiaryContainer),
              ),
            );
          }

          final profile = state.profile;
          if (profile == null) {
            return const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Text('No se pudo cargar el perfil.'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Page header ──────────────────────────────────────
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Profile', style: AppTextStyles.headlineLg),
                            const SizedBox(height: 2),
                            Text('Manage your professional information',
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _openEditDialog(context, profile),
                          icon: const Icon(Symbols.edit, size: 18),
                          label: const Text('Edit Profile'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.onTertiaryContainer,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Profile header card ───────────────────────────────
                    _ProfileHeaderCard(profile: profile),
                    const SizedBox(height: 20),

                    // ── Two-column body ───────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _SkillsCard(skills: profile.skills)),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 300,
                          child: _ProfileCompletionCard(profile: profile),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, CandidateProfile profile) async {
    final cubit = context.read<CandidateCubit>();
    await cubit.loadCategories();
    if (profile.primaryCategoryId != null) {
      await cubit.loadSkillsByCategory(profile.primaryCategoryId!);
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ProfileEditDialog(profile: profile),
      ),
    );
  }
}

// ─── Profile header card ──────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});
  final CandidateProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: AppTextStyles.headlineLg.copyWith(
                                color: AppColors.onPrimary, fontSize: 30),
                          )
                        : null,
                  ),
                  if (profile.profileStrength == 100)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.onTertiaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Symbols.verified,
                            size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),

              // Name + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppTextStyles.headlineMd),
                    if (profile.headline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(profile.headline,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoPill(icon: Symbols.mail, label: profile.email),
                        if (profile.seniority != null)
                          _InfoPill(
                            icon: Symbols.trending_up,
                            label: '${profile.seniority![0].toUpperCase()}${profile.seniority!.substring(1)}',
                          ),
                        if (profile.experienceYears != null)
                          _InfoPill(
                            icon: Symbols.work_history,
                            label: '${profile.experienceYears}y experience',
                          ),
                        if (profile.englishLevel != null)
                          _InfoPill(
                            icon: Symbols.language,
                            label: 'English ${profile.englishLevel}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Links row
          if (profile.githubUrl != null || profile.linkedinUrl != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                if (profile.githubUrl != null)
                  _LinkChip(
                    icon: Symbols.code,
                    label: 'GitHub',
                    url: profile.githubUrl!,
                  ),
                if (profile.linkedinUrl != null)
                  _LinkChip(
                    icon: Symbols.business_center,
                    label: 'LinkedIn',
                    url: profile.linkedinUrl!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.outline),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;

  Future<void> _launch() async {
    final raw = url.trim();
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            border: Border.all(
                color: AppColors.onPrimaryContainer.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Symbols.open_in_new, size: 12, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skills card ──────────────────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills});
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.psychology, size: 20, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Skills', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
              const Spacer(),
              if (skills.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.onTertiaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${skills.length}',
                      style: AppTextStyles.labelBold
                          .copyWith(color: AppColors.onTertiaryContainer)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (skills.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Symbols.add_circle,
                      size: 36, color: AppColors.outlineVariant),
                  const SizedBox(height: 10),
                  Text('No skills added yet',
                      style: AppTextStyles.labelBold
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Click "Edit Profile" to add your skills',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.outline)),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => _SkillChip(label: s)).toList(),
            ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.2),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.secondary, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Profile completion card ─────────────────────────────────────────────────

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.profile});
  final CandidateProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CompletionItem('Profile photo', profile.avatarUrl != null),
      _CompletionItem('Skills added', profile.skills.isNotEmpty),
      _CompletionItem('Seniority set', profile.seniority != null),
      _CompletionItem('Experience years', profile.experienceYears != null),
      _CompletionItem('English level', profile.englishLevel != null),
      _CompletionItem('GitHub linked', profile.githubUrl != null),
      _CompletionItem('LinkedIn linked', profile.linkedinUrl != null),
    ];
    final completedCount = items.where((i) => i.isDone).length;
    final pct = (completedCount / items.length * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.bar_chart, size: 20, color: AppColors.onTertiaryContainer),
              const SizedBox(width: 8),
              Text('Profile Strength',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),

          // Percentage + bar
          Row(
            children: [
              Text('$pct%',
                  style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.onTertiaryContainer, fontSize: 28)),
              const Spacer(),
              Text('$completedCount/${items.length}',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct == 100
                    ? AppColors.onTertiaryContainer
                    : AppColors.secondary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 12),

          // Checklist
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      item.isDone
                          ? Symbols.check_circle
                          : Symbols.radio_button_unchecked,
                      size: 18,
                      color: item.isDone
                          ? AppColors.onTertiaryContainer
                          : AppColors.outlineVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(item.label,
                        style: AppTextStyles.labelSm.copyWith(
                          color: item.isDone
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          decoration: item.isDone
                              ? null
                              : null,
                        )),
                  ],
                ),
              )),

          if (pct < 100) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    (context.findAncestorStateOfType<_CandidateProfilePageState>())
                        ?._openEditDialog(
                            context,
                            profile,
                          ),
                icon: const Icon(Symbols.edit, size: 16),
                label: const Text('Complete Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onTertiaryContainer,
                  side: const BorderSide(color: AppColors.onTertiaryContainer),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionItem {
  const _CompletionItem(this.label, this.isDone);
  final String label;
  final bool isDone;
}

// ─── Edit Dialog ─────────────────────────────────────────────────────────────

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.profile});
  final CandidateProfile profile;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final _yearsCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();

  String _seniority = 'junior';
  String _englishLevel = 'B1';

  Category? _selectedCategory;
  final Map<int, int> _selectedSkills = {};

  static const _seniorityOptions = ['junior', 'mid', 'senior'];
  static const _englishOptions = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _yearsCtrl.text = p.experienceYears?.toString() ?? '';
    _githubCtrl.text = p.githubUrl ?? '';
    _linkedinCtrl.text = p.linkedinUrl ?? '';
    _photoCtrl.text = p.avatarUrl ?? '';
    if (p.seniority != null && _seniorityOptions.contains(p.seniority)) {
      _seniority = p.seniority!;
    }
    if (p.englishLevel != null && _englishOptions.contains(p.englishLevel)) {
      _englishLevel = p.englishLevel!;
    }
    // Pre-populate skills (IDs already loaded before dialog opened)
    for (final entry in p.skillEntries) {
      _selectedSkills[entry.id] = entry.level;
    }
    // Pre-select category after first frame (categories are in state by now)
    if (p.primaryCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cats = context.read<CandidateCubit>().state.categories;
        final cat = cats.where((c) => c.id == p.primaryCategoryId).firstOrNull;
        if (cat != null) setState(() => _selectedCategory = cat);
      });
    }
  }

  @override
  void dispose() {
    _yearsCtrl.dispose();
    _githubCtrl.dispose();
    _linkedinCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  void _onCategoryTap(Category cat) {
    setState(() {
      if (_selectedCategory?.id == cat.id) {
        _selectedCategory = null;
        context.read<CandidateCubit>().clearCatalogSkills();
      } else {
        _selectedCategory = cat;
        context.read<CandidateCubit>().loadSkillsByCategory(cat.id);
      }
    });
  }

  void _toggleSkill(CatalogSkill skill) {
    setState(() {
      if (_selectedSkills.containsKey(skill.id)) {
        _selectedSkills.remove(skill.id);
      } else {
        _selectedSkills[skill.id] = 3;
      }
    });
  }

  Future<void> _save() async {
    final cubit = context.read<CandidateCubit>();
    final skillsList = _selectedSkills.entries
        .map((e) => {'skillId': e.key, 'level': e.value})
        .toList();

    // Fall back to existing profile data if the user didn't change category/skills
    final profile = widget.profile;
    final categoryIds = _selectedCategory != null
        ? [_selectedCategory!.id]
        : (profile.primaryCategoryId != null ? [profile.primaryCategoryId!] : <int>[]);
    final skills = skillsList.isNotEmpty
        ? skillsList
        : profile.skillEntries
            .map((e) => {'skillId': e.id, 'level': e.level})
            .toList();

    await cubit.updateProfile(
      experienceYears: int.tryParse(_yearsCtrl.text),
      seniority: _seniority,
      englishLevel: _englishLevel,
      githubLink:
          _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
      linkedinUrl:
          _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
      profilePhotoUrl:
          _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim(),
      categoryIds: categoryIds,
      skills: skills,
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 740),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.navyGradient,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Row(
                children: [
                  const Icon(Symbols.edit,
                      color: AppColors.onTertiaryContainer, size: 22),
                  const SizedBox(width: 12),
                  Text('Edit Profile',
                      style: AppTextStyles.headlineMd
                          .copyWith(color: AppColors.onPrimary)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close,
                        color: AppColors.onPrimaryContainer),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Professional Info'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: 'Years of Experience',
                            child: TextFormField(
                              controller: _yearsCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: AppTextStyles.bodyMd,
                              decoration: _dec('e.g. 3'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _FormField(
                            label: 'Seniority Level',
                            child: DropdownButtonFormField<String>(
                              value: _seniority,
                              decoration: _dec(null),
                              dropdownColor: AppColors.surfaceContainer,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.onSurface),
                              items: _seniorityOptions
                                  .map((v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(
                                            '${v[0].toUpperCase()}${v.substring(1)}'),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _seniority = v!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _FormField(
                            label: 'English Level',
                            child: DropdownButtonFormField<String>(
                              value: _englishLevel,
                              decoration: _dec(null),
                              dropdownColor: AppColors.surfaceContainer,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.onSurface),
                              items: _englishOptions
                                  .map((v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _englishLevel = v!),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel('Links'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: 'GitHub URL',
                            child: TextFormField(
                              controller: _githubCtrl,
                              style: AppTextStyles.bodyMd,
                              decoration: _dec('https://github.com/...'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _FormField(
                            label: 'LinkedIn URL',
                            child: TextFormField(
                              controller: _linkedinCtrl,
                              style: AppTextStyles.bodyMd,
                              decoration: _dec('https://linkedin.com/in/...'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      label: 'Profile Photo URL',
                      child: TextFormField(
                        controller: _photoCtrl,
                        style: AppTextStyles.bodyMd,
                        decoration: _dec('https://...'),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel('Specialty'),
                    const SizedBox(height: 4),
                    Text('Select your primary area',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.outline)),
                    const SizedBox(height: 12),
                    BlocBuilder<CandidateCubit, CandidateState>(
                      buildWhen: (a, b) => a.categories != b.categories,
                      builder: (context, state) {
                        if (state.categories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onTertiaryContainer),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.categories
                              .map((cat) => _CategoryChip(
                                    label: cat.name,
                                    isSelected:
                                        _selectedCategory?.id == cat.id,
                                    onTap: () => _onCategoryTap(cat),
                                  ))
                              .toList(),
                        );
                      },
                    ),

                    BlocBuilder<CandidateCubit, CandidateState>(
                      buildWhen: (a, b) =>
                          a.catalogSkills != b.catalogSkills,
                      builder: (context, state) {
                        if (state.catalogSkills.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _SectionLabel('Skills'),
                            const SizedBox(height: 4),
                            Text('Tap to add · tap stars to set proficiency',
                                style: AppTextStyles.labelSm
                                    .copyWith(color: AppColors.outline)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.catalogSkills
                                  .map((skill) => _SkillSelector(
                                        skill: skill,
                                        level: _selectedSkills[skill.id],
                                        onToggle: () => _toggleSkill(skill),
                                        onLevelChanged: (lvl) => setState(
                                            () => _selectedSkills[skill.id] =
                                                lvl),
                                      ))
                                  .toList(),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.outlineVariant)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: BlocBuilder<CandidateCubit, CandidateState>(
                buildWhen: (a, b) =>
                    a.isSavingProfile != b.isSavingProfile,
                builder: (context, state) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: state.isSavingProfile
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: state.isSavingProfile ? null : _save,
                      icon: state.isSavingProfile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Symbols.save, size: 18),
                      label: Text(state.isSavingProfile
                          ? 'Saving…'
                          : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd
            .copyWith(color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppColors.onTertiaryContainer, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      );
}

// ─── Shared form helpers ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.labelBold.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.6,
            fontSize: 11));
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.onTertiaryContainer
              : AppColors.surfaceContainer,
          border: Border.all(
            color: isSelected
                ? AppColors.onTertiaryContainer
                : AppColors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SkillSelector extends StatelessWidget {
  const _SkillSelector({
    required this.skill,
    required this.level,
    required this.onToggle,
    required this.onLevelChanged,
  });
  final CatalogSkill skill;
  final int? level;
  final VoidCallback onToggle;
  final ValueChanged<int> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    final selected = level != null;
    // Label and stars are SIBLING gesture zones (not nested) so tapping a star
    // never triggers the toggle that would immediately deselect the skill.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.4)
            : AppColors.surfaceContainer,
        border: Border.all(
          color: selected
              ? AppColors.onTertiaryContainer
              : AppColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label: tap to toggle selection ─────────────────────────
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                top: 7,
                bottom: 7,
                right: selected ? 6 : 12,
              ),
              child: Text(
                skill.name,
                style: AppTextStyles.labelSm.copyWith(
                  color: selected
                      ? AppColors.onTertiaryContainer
                      : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // ── Stars: tap to set level — separate from label zone ─────
          if (selected) ...[
            ...List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => onLevelChanged(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2, vertical: 8),
                  child: Icon(
                    star <= (level ?? 0)
                        ? Symbols.star
                        : Symbols.star_outline,
                    size: 15,
                    color: AppColors.onTertiaryContainer,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
