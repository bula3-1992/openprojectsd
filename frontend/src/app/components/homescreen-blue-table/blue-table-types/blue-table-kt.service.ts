import {BlueTableService} from "core-components/homescreen-blue-table/blue-table.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";

export class BlueTableKtService extends BlueTableService {
  protected columns:string[] = ['Мероприятие', 'Отв. Исполнитель', 'Срок выполнения', 'Статус', 'Факт. выполнение', 'Проблемы'];
  private project:string;
  private limit:string | undefined;
  private filter:string | undefined;
  private page:number = 0;
  private national_project_titles:{ id:number, name:string }[];
  private national_projects:HalResource[];

  public initializeAndGetData():Promise<any[]> {
    this.filter = undefined;
    this.limit = undefined;
    this.page = 0;
    return new Promise((resolve) => {
      this.national_project_titles = [];
      this.halResourceService
        .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.national_projects.toString(), {context: 'kt'})
        .toPromise()
        .then((resources:CollectionResource<HalResource>) => {
          this.national_projects = resources.elements;
          this.national_projects.map((el:HalResource) => {
            if (!el.parentId) {
              this.national_project_titles.push({id: el.id, name: el.name});
            }
          });
          this.national_project_titles.push({id: 0, name: 'Проекты Республики Бурятия'});
          this.getDataFromPage(0).then(data => {
            resolve(data);
          });
        });
    });
  }

  public getPages():number {
    if (!this.project || this.project === '0') {
      return this.national_project_titles.length;
    } else {
      return this.pages;
    }
  }

  public pagesToText(i:number):string {
    if (!this.project || this.project === '0') {
      return this.national_project_titles[i].name;
    } else {
      return String(i + 1);
    }
  }

  public getDataFromPage(i:number):Promise<any[]> {
    return new Promise((resolve) => {
      let data:any[] = [];
      let data_local:any = {};
      this.page = i;
      if (!this.project || this.project === '0') {
        let params:any = {national: this.national_project_titles[this.page].id};
        if (this.limit) {
          params.limit = this.limit;
        }
        if (this.filter) {
          params.filter = this.filter;
        }
        this.halResourceService
          .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.work_package_ispoln_stat_view.toString(), params)
          .toPromise()
          .then((resource:CollectionResource<HalResource>) => {
            resource.elements.map((el:HalResource) => {
              if ((el.federal_id !== 0) || (el.federal_id === 0 && el.national_id === 0)) {
                data_local[el.federal_id] = data_local[el.federal_id] || [];
                data_local[el.federal_id].push(el);
              } else {
                data_local[el.national_id] = data_local[el.national_id] || [];
                data_local[el.national_id].push(el);
              }
            });
            this.national_projects.map((el:HalResource) => {
              if ((el.id === this.national_project_titles[this.page].id) || (el.parentId && el.parentId === this.national_project_titles[this.page].id)) {
                data.push(el);
                if (data_local[el.id]) {
                  data_local[el.id].map((row:HalResource) => {
                    data.push({_type: row._type, identifier: row.identifier, name: row.name});
                    row.work_packages.map((wp:HalResource) => {
                      data.push(wp);
                    });
                  });
                }
              }
            });
            if (this.national_project_titles[i].id === 0) {
              data.push({_type: 'NationalProject', id: 0, name: 'Проекты Республики Бурятия'});
              if (data_local[0]) {
                data_local[0].map((row:HalResource) => {
                  data.push({_type: row._type, identifier: row.identifier, name: row.name});
                  row.work_packages.map((wp:HalResource) => {
                    data.push(wp);
                  });
                });
              }
            }
            resolve(data);
          });
      } else {
        this.page += 1;
        let params:any = {project: this.project, offset: this.page};
        if (this.limit) {
          params.limit = this.limit;
        }
        if (this.filter) {
          params.filter = this.filter;
        }
        this.halResourceService
          .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.work_package_ispoln_stat_view.toString(), params)
          .toPromise()
          .then((resource:CollectionResource<HalResource>) => {
            resource.elements.map((el:HalResource) => {
              if ((el.federal_id !== 0) || (el.federal_id === 0 && el.national_id === 0)) {
                data_local[el.federal_id] = [el];
              } else {
                data_local[el.national_id] = [el];
              }
            });
            resource.elements.map((project:HalResource) => {
              this.national_projects.map((el:HalResource) => {
                if ((el.id === project.federal_id) || (el.parentId && el.parentId === project.national_id) || (el.id === project.national_id)) {
                  data.push(el);
                  if (data_local[el.id]) {
                    data_local[el.id].map((row:HalResource) => {
                      data.push({_type: row._type, identifier: row.identifier, name: row.name});
                      row.work_packages.map((wp:HalResource) => {
                        data.push(wp);
                      });
                    });
                  }
                }
              });
              if (project.national_id === 0) {
                data.push({_type: 'NationalProject', id: 0, name: 'Проекты Республики Бурятия'});
                if (data_local[0]) {
                  data_local[0].map((row:HalResource) => {
                    data.push({_type: row._type, identifier: row.identifier, name: row.name});
                    row.work_packages.map((wp:HalResource) => {
                      data.push(wp);
                    });
                  });
                }
              }
            });
            resolve(data);
          });
      }
    });
  }

  public getTdData(row:any, i:number):string {
    if (row._type === 'NationalProject') {
      switch (i) {
        case 0: {
          return row.name;
          break;
        }
      }
    } else if (row._type === 'Project') {
      switch (i) {
        case 0: {
          return '<a href="' + super.getBasePath() + '/projects/' + row.identifier + '">' + row.name + '</a>';
          break;
        }
      }
    } else {
      switch (i) {
        case 0: {
          return '<a href="' + super.getBasePath() + '/work_packages/' + row.work_package_id + '/activity?plan_type=execution">' + row.subject + '</a>';
          break;
        }
        case 1: {
          return row.otvetstvenniy;
          break;
        }
        case 2: {
          return this.format(row.due_date);
          break;
        }
        case 3: {
          return row.status_name;
          break;
        }
        case 4: {
          return this.format(row.fakt_ispoln);
          break;
        }
        case 5: {
          return '<a href="' + this.getBasePath() + '/vkladka1/problems?id=' + row.project_id + '">' + row.created_problem_count + '</a>';
          break;
        }
      }
    }
    return '';
  }

  public getTdClass(row:any, i:number):string {
    switch (i) {
      case 0: {
        if (row._type === 'Project') {
          return 'p30';
        }
        if (row._type === 'WorkPackageIspolnStat') {
          return 'p40';
        }
        return row.parentId == null ? 'p10' : 'p20';
        break;
      }
    }
    return '';
  }
  public getTrClass(row:any):string {
    if (row._type === 'WorkPackageIspolnStat') {
      if (row.ispolneno) {
        return 'colored-row-green';
      } else if (row.days_to_due < 0 || row.days_to_due == null) {
        return 'colored-row-red';
      }  else if ((row.v_rabote || row.est_riski) && row.days_to_due != null && row.days_to_due >= 0 && row.days_to_due <= 14) {
        return 'colored-row-yellow';
      } else if (row.v_rabote || row.est_riski) {
        return 'colored-row';
      }
    return '';
    } else {
  return 'colored-row';
    }
  }
  public getDataWithFilter(param:string):Promise<any[]> {
    return new Promise((resolve) => {
      let data:any[] = [];
      let data_local:any = {};
      if (param.startsWith('project')) {
        this.project = param.slice(7);
        this.limit = undefined;
        this.filter = undefined;
        this.page = 0;
      } else if (param.startsWith('limit')) {
        this.limit = param.slice(5);
      } else {
        this.filter = param;
        if (param === 'predstoyashie' || param === 'all') {
          this.limit = undefined;
        }
      }
      if (!this.project || this.project === '0') {
        let params:any = {national: this.national_project_titles[this.page].id};
        if (this.limit) {
          params.limit = this.limit;
        }
        if (this.filter) {
          params.filter = this.filter;
        }
        this.halResourceService
          .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.work_package_ispoln_stat_view.toString(), params)
          .toPromise()
          .then((resource:CollectionResource<HalResource>) => {
            resource.elements.map((el:HalResource) => {
              if ((el.federal_id !== 0) || (el.federal_id === 0 && el.national_id === 0)) {
                data_local[el.federal_id] = data_local[el.federal_id] || [];
                data_local[el.federal_id].push(el);
              } else {
                data_local[el.national_id] = data_local[el.national_id] || [];
                data_local[el.national_id].push(el);
              }
            });
            if (this.national_project_titles[this.page].id === 0) {
              data.push({_type: 'NationalProject', id: 0, name: 'Проекты Республики Бурятия'});
              if (data_local[0]) {
                data_local[0].map((row:HalResource) => {
                  data.push({_type: row._type, identifier: row.identifier, name: row.name});
                  row.work_packages.map((wp:HalResource) => {
                    data.push(wp);
                  });
                });
              }
            }
            this.national_projects.map((el:HalResource) => {
              if ((el.id === this.national_project_titles[this.page].id) || (el.parentId && el.parentId === this.national_project_titles[this.page].id)) {
                data.push(el);
                if (data_local[el.id]) {
                  data_local[el.id].map((row:HalResource) => {
                    data.push({_type: row._type, identifier: row.identifier, name: row.name});
                    row.work_packages.map((wp:HalResource) => {
                      data.push(wp);
                    });
                  });
                }
              }
            });
            resolve(data);
          });
      } else {
        this.page = 1;
        let params:any = {project: this.project, offset: this.page};
        if (this.limit) {
          params.limit = this.limit;
        }
        if (this.filter) {
          params.filter = this.filter;
        }
        this.halResourceService
          .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.work_package_ispoln_stat_view.toString(), params)
          .toPromise()
          .then((resource:CollectionResource<HalResource>) => {
            let total:number = resource.total; //всего ex 29
            let pageSize:number = resource.pageSize; //в этой выборке ex 20
            let remainder = total % pageSize;
            this.pages = (total - remainder) / pageSize;
            if (remainder !== 0) {
              this.pages++;
            }
            resource.elements.map((el:HalResource) => {
              if ((el.federal_id !== 0) || (el.federal_id === 0 && el.national_id === 0)) {
                data_local[el.federal_id] = [el];
              } else {
                data_local[el.national_id] = [el];
              }
            });
            resource.elements.map((project:HalResource) => {
              this.national_projects.map((el:HalResource) => {
                if ((el.id === project.federal_id) || (el.parentId && el.parentId === project.national_id) || (el.id === project.national_id)) {
                  data.push(el);
                  if (data_local[el.id]) {
                    data_local[el.id].map((row:HalResource) => {
                      data.push({_type: row._type, identifier: row.identifier, name: row.name});
                      row.work_packages.map((wp:HalResource) => {
                        data.push(wp);
                      });
                    });
                  }
                }
              });
              if (project.national_id === 0) {
                data.push({_type: 'NationalProject', id: 0, name: 'Проекты Республики Бурятия'});
                if (data_local[0]) {
                  data_local[0].map((row:HalResource) => {
                    data.push({_type: row._type, identifier: row.identifier, name: row.name});
                    row.work_packages.map((wp:HalResource) => {
                      data.push(wp);
                    });
                  });
                }
              }
            });
            resolve(data);
          });
      }
    });
  }

  public format(input:string):string {
    if (input) {
      return input.slice(8, 10) + '.' + input.slice(5, 7) + '.' + input.slice(0, 4);
    } else {
      return '';
    }
  }
}
