import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/job_offer.dart';
import '../../domain/entities/user.dart';
import '../bloc/company_cubit.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_sidebar.dart';
import '../widgets/shared/app_text_field.dart';

class CreateNewOfferPage extends StatefulWidget {
  const CreateNewOfferPage({super.key});

  @override
  State<CreateNewOfferPage> createState() => _CreateNewOfferPageState();
}

class _CreateNewOfferPageState extends State<CreateNewOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final _rawDescCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _positionsCtrl = TextEditingController(text: '1');

  String _modality = 'remote';
  String? _englishLevel;
  int? _selectedTierId;
  int? _selectedCategoryId;
  final Set<int> _selectedSkillIds = {};
  final Set<int> _selectedCategoryIds = {};
  bool _showAiSuggestions = false;

  static const _englishLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _modalityOptions = ['remote', 'hybrid', 'onsite'];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CompanyCubit>();
    cubit.loadTiers();
    cubit.loadCategories();
  }

  @override
  void dispose() {
    _rawDescCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _salaryCtrl.dispose();
    _expCtrl.dispose();
    _positionsCtrl.dispose();
    super.dispose();
  }

  void _applyAiResult(AiParseResult r) {
    if (r.title != null) _titleCtrl.text = r.title!;
    if (r.modality != null) setState(() => _modality = r.modality!);
    if (r.salary != null) _salaryCtrl.text = r.salary.toString();
    if (r.minExperienceYears != null) _expCtrl.text = r.minExperienceYears.toString();
    if (r.requiredEnglishLevel != null) setState(() => _englishLevel = r.requiredEnglishLevel);
    if (r.suggestedCategoryIds.isNotEmpty) {
      setState(() => _selectedCategoryIds.addAll(r.suggestedCategoryIds));
    }
    if (r.suggestedSkillIds.isNotEmpty) {
      setState(() => _selectedSkillIds.addAll(r.suggestedSkillIds));
    }
    setState(() => _showAiSuggestions = true);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedTierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan tier')),
      );
      return;
    }
    final salary = int.tryParse(_salaryCtrl.text.trim());
    final exp = int.tryParse(_expCtrl.text.trim());
    final positions = int.tryParse(_positionsCtrl.text.trim()) ?? 1;
    context.read<CompanyCubit>().createOffer(CreateOfferInput(
          title: _titleCtrl.text.trim(),
          modality: _modality,
          tierId: _selectedTierId!,
          description: _descCtrl.text.trim(),
          salary: salary,
          minExperienceYears: exp,
          requiredEnglishLevel: _englishLevel,
          positionsAvailable: positions,
          categoryIds: _selectedCategoryIds.toList(),
          skillIds: _selectedSkillIds.toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyCubit, CompanyState>(
      listenWhen: (prev, curr) =>
          curr.aiParseResult != prev.aiParseResult ||
          curr.createdOffer != prev.createdOffer ||
          curr.checkoutUrl != prev.checkoutUrl,
      listener: (context, state) async {
        if (state.aiParseResult != null) {
          _applyAiResult(state.aiParseResult!);
        }
        if (state.checkoutUrl != null) {
          final uri = Uri.tryParse(state.checkoutUrl!);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) context.go(AppRoutes.companyDashboard);
        } else if (state.createdOffer != null && !state.isSaving) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offer created!'),
                backgroundColor: AppColors.onTertiaryContainer,
              ),
            );
            context.go(AppRoutes.companyDashboard);
          }
        }
      },
      child: ScaffoldWithSidebar(
        currentRoute: AppRoutes.createOffer,
        role: UserRole.company,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: BlocBuilder<CompanyCubit, CompanyState>(
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go(AppRoutes.companyDashboard),
                            icon: const Icon(Symbols.arrow_back, color: AppColors.onSurface),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create New Offer', style: AppTextStyles.headlineLg),
                              Text('Post a position and let AI find the best candidates',
                                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // AI Description Parser
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.emeraldGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Symbols.auto_awesome, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text('AI Description Parser',
                                    style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
                                const Spacer(),
                                Text('Optional',
                                    style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Paste a job description and let AI pre-fill the form fields.',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _rawDescCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Paste your raw job description here...',
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (state.isParsing)
                              const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2,
                                            color: AppColors.onTertiaryContainer)),
                                    SizedBox(width: 10),
                                    Text('Analyzing with AI...'),
                                  ],
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () {
                                  final text = _rawDescCtrl.text.trim();
                                  if (text.isNotEmpty) {
                                    context.read<CompanyCubit>().parseDescription(text);
                                  }
                                },
                                icon: const Icon(Symbols.auto_awesome, size: 16),
                                label: const Text('Parse with AI'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.onTertiaryContainer,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            if (_showAiSuggestions && state.aiParseResult?.confidenceNote != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.onTertiaryContainer.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.onTertiaryContainer.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Symbols.info, size: 16, color: AppColors.onTertiaryContainer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(state.aiParseResult!.confidenceNote!,
                                          style: AppTextStyles.labelSm
                                              .copyWith(color: AppColors.onTertiaryContainer)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Basic Info
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Basic Information',
                                style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Job Title',
                              hint: 'e.g. Senior React Developer',
                              prefixIcon: Symbols.work,
                              controller: _titleCtrl,
                              validator: (v) =>
                                  v != null && v.isNotEmpty ? null : 'Required',
                            ),
                            const SizedBox(height: 16),
                            // Modality
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Work Mode', style: AppTextStyles.labelBold),
                                const SizedBox(height: 8),
                                Row(
                                  children: _modalityOptions
                                      .map((m) => Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: _OptionChip(
                                                label: m[0].toUpperCase() + m.substring(1),
                                                selected: _modality == m,
                                                onTap: () => setState(() => _modality = m),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Monthly Salary (COP)',
                                    hint: 'e.g. 5000000',
                                    prefixIcon: Symbols.payments,
                                    controller: _salaryCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Min. Experience (years)',
                                    hint: 'e.g. 3',
                                    prefixIcon: Symbols.timeline,
                                    controller: _expCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('English Level', style: AppTextStyles.labelBold),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: _englishLevel,
                                        decoration: const InputDecoration(hintText: 'Not required'),
                                        items: [
                                          const DropdownMenuItem(value: null, child: Text('Not required')),
                                          ..._englishLevels.map((l) =>
                                              DropdownMenuItem(value: l, child: Text(l))),
                                        ],
                                        onChanged: (v) => setState(() => _englishLevel = v),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Open Positions',
                                    hint: '1',
                                    prefixIcon: Symbols.group,
                                    controller: _positionsCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Job Description',
                                style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Describe responsibilities, requirements, and what makes this role unique.',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descCtrl,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText: 'Write a compelling job description...',
                              ),
                              validator: (v) =>
                                  v != null && v.length >= 20 ? null : 'Minimum 20 characters',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Categories & Skills
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Categories & Skills',
                                style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Select relevant categories and skills for AI matching.',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            if (state.categories.isEmpty)
                              const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.onTertiaryContainer))
                            else ...[
                              Text('Category', style: AppTextStyles.labelBold),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: state.categories.map((c) => _OptionChip(
                                      label: c.name,
                                      selected: _selectedCategoryIds.contains(c.id),
                                      onTap: () {
                                        setState(() {
                                          if (_selectedCategoryIds.contains(c.id)) {
                                            _selectedCategoryIds.remove(c.id);
                                          } else {
                                            _selectedCategoryIds.add(c.id);
                                            _selectedCategoryId = c.id;
                                          }
                                        });
                                        context.read<CompanyCubit>().loadSkillsByCategory(c.id);
                                      },
                                    )).toList(),
                              ),
                              if (_selectedCategoryId != null && state.availableSkills.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text('Skills', style: AppTextStyles.labelBold),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: state.availableSkills.map((s) => _OptionChip(
                                        label: s.name,
                                        selected: _selectedSkillIds.contains(s.id),
                                        onTap: () => setState(() {
                                          if (_selectedSkillIds.contains(s.id)) {
                                            _selectedSkillIds.remove(s.id);
                                          } else {
                                            _selectedSkillIds.add(s.id);
                                          }
                                        }),
                                      )).toList(),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tier Selector
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Plan', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Choose how many top-ranked candidates you want to receive.',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            if (state.tiers.isEmpty)
                              const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.onTertiaryContainer))
                            else
                              ...state.tiers.map((tier) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _TierCard(
                                      tier: tier,
                                      selected: _selectedTierId == tier.id,
                                      onTap: () => setState(() => _selectedTierId = tier.id),
                                    ),
                                  )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go(AppRoutes.companyDashboard),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.outlineVariant),
                              foregroundColor: AppColors.onSurface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: _selectedTierId != null ? 'Create & Pay' : 'Create Offer',
                            isEmerald: true,
                            isLoading: state.isSaving,
                            icon: Symbols.publish,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
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

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onTertiaryContainer.withOpacity(0.12)
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected ? AppColors.onTertiaryContainer : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.onTertiaryContainer : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.selected,
    required this.onTap,
  });
  final OfferTier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onTertiaryContainer.withOpacity(0.06)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.onTertiaryContainer : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.onTertiaryContainer
                      : AppColors.outlineVariant,
                  width: 2,
                ),
                color: selected ? AppColors.onTertiaryContainer : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier.name, style: AppTextStyles.labelBold),
                  Text(tier.candidatesLabel,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Text(tier.priceLabel,
                style: AppTextStyles.headlineMd.copyWith(
                    fontSize: 18,
                    color: selected
                        ? AppColors.onTertiaryContainer
                        : AppColors.onSurface)),
          ],
        ),
      ),
    );
  }
}
