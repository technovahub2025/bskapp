enum AppRole {
  projectManager('Project Manager', 'Manage projects, teams, and progress', 'project_manager', 'PM'),
  siteEngineer('Site Engineer', 'Track your assigned work on site', 'site_engineer', 'SE'),
  estimator('Estimator', 'Review project quantities, labour, and materials', 'estimator', 'ES'),
  contractor('Contractor', 'Coordinate work and project delivery', 'contractor', 'CO');

  const AppRole(this.label, this.description, this.apiValue, this.initials);
  final String label;
  final String description;
  final String apiValue;
  final String initials;
}
