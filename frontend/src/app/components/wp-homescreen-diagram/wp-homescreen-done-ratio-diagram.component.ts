import {Component, Input, OnInit} from '@angular/core';
import {ChartOptions, ChartType, ChartDataSets} from 'chart.js';
import {Label} from 'ng2-charts';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {appBaseSelector, ApplicationBaseComponent} from "core-app/modules/router/base/application-base.component";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";
import {ProjectCacheService} from "core-components/projects/project-cache.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";

export const homescreenDiagramSelector = 'wp-homescreen-done-ratio-diagram';

@Component({
  selector: homescreenDiagramSelector,
  templateUrl: './wp-homescreen-done-ratio-diagram.html'
})
export class WorkPackageHomescreenDoneRatioDiagramComponent implements OnInit {
  public barChartOptions:ChartOptions = {
    responsive: true,
  };
  public barChartLabels:Label[] = [];
  public barChartType:ChartType = 'bar';
  public barChartLegend = true;
  public barChartPlugins = [];
  public barChartData:ChartDataSets[] = [
    {data:[], label: 'Количество'},
    {data:[], label: 'Процент выполнения'}
  ];
  public wpCounts:number[] = [];
  public percentageDones:number[] = [];

  constructor(protected I18n:I18nService,
              //bbm(
              protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService) { }

  ngOnInit() {
    this.halResourceService
      .get<CollectionResource>(this.pathHelper.api.v3.projects.toString())
      .toPromise()
      .then((resource:CollectionResource<ProjectResource>) => {
        resource.elements.map(project => this.registerDataSet(project));
      });
  }

  protected registerDataSet(projectResource:ProjectResource):void {
    this.wpCounts.push(projectResource.wpCount);
    this.percentageDones.push(projectResource.percentageDone);
    this.barChartLabels.push(projectResource.name);
    this.barChartData[0].data = this.wpCounts;
    this.barChartData[1].data = this.percentageDones;
  }
}

DynamicBootstrapper.register({ selector: homescreenDiagramSelector, cls: WorkPackageHomescreenDoneRatioDiagramComponent });
