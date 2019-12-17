import {BlueTableService} from "core-components/homescreen-blue-table/blue-table.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";

export class BlueTableProtocolService extends BlueTableService {
  protected columns:string[] = ['', 'Ответственный', 'Срок', 'Исполнение'];
  private data_local:any;
  private national_project_titles:{ id:number, name:string }[];
  private national_projects:HalResource[];

  public initializeAndGetData():Promise<any[]> {
    return new Promise((resolve) => {
      let data_local:any = {};
      this.national_project_titles = [];
      this.halResourceService
        .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.national_projects.toString(), {context: "protocol"})
        .toPromise()
        .then((resources:CollectionResource<HalResource>) => {
          this.national_projects = resources.elements;
          this.national_projects.map((el:HalResource) => {
            if (!el.parentId) {
              this.national_project_titles.push({id: el.id, name: el.name});
            }
          });
          this.national_project_titles.push({id: 0, name: 'Проекты Республики Бурятия'});

          this.halResourceService
            .get<CollectionResource<HalResource>>(this.pathHelper.api.v3.protocols.toString())
            .toPromise()
            .then((resources:CollectionResource<HalResource>) => {
              resources.elements.map((protocol:HalResource) => {
                if (!protocol.project.federal_project_id) {
                  protocol.project.federal_project_id = 0;
                }
                if (!protocol.project.national_project_id) {
                  protocol.project.national_project_id = 0;
                }

                if ((protocol.project.federal_project_id !== 0) || (protocol.project.federal_project_id === 0 && protocol.project.national_project_id === 0)) {
                  data_local[protocol.project.federal_project_id] = data_local[protocol.project.federal_project_id] || [];
                  data_local[protocol.project.federal_project_id].push(protocol);
                } else {
                  data_local[protocol.project.national_project_id] = data_local[protocol.project.national_project_id] || [];
                  data_local[protocol.project.national_project_id].push(protocol);
                }
              });
              this.data_local = data_local;
              this.getDataFromPage(0).then(data => {
                resolve(data);
              });
            });
        });
    });
  }

  public getDataFromPage(i:number):Promise<any[]> {
    return new Promise((resolve) => {
      let data:any[] = [];
      if (this.national_project_titles[i].id === 0) {
        data.push({_type: 'NationalProject', id: 0, name: 'Проекты Республики Бурятия'});
        if (this.data_local[0]) {
          this.data_local[0].map((project:ProjectResource) => {
            data.push(project);
          });
        }
      } else {
        this.national_projects.map((el:HalResource) => {
          if ((el.id === this.national_project_titles[i].id) || (el.parentId && el.parentId === this.national_project_titles[i].id)) {
            data.push(el);
            if (this.data_local[el.id]) {
              this.data_local[el.id].map((project:ProjectResource) => {
                data.push(project);
              });
            }
          }
        });
      }
      resolve(data);
    });
  }

  public getTdData(row:any, i:number):string {
    if (row._type === 'Protocol') {
      switch (i) {
        case 0: {
          return '<a href="' + super.getBasePath() + '/meetings/' + row.meetingId + '/minutes">Поручение: ' + row.name + '</a>';
          break;
        }
        case 1: {
          if (row.user) {
            let fio = row.user.lastname + ' ' + row.user.firstname.slice(0, 1) + '.';
            if (row.user.patronymic) {
              fio += row.user.patronymic.slice(0, 1) + '.';
            }
            return '<a href="' + super.getBasePath() + '/users/' + row.user.id + '">' + fio + '</a>';
          }
          break;
        }
        case 2: {
          return this.format(row.dueDate);
          break;
        }
        case 3: {
          if (row.completed) {
            return 'Исполнено';
          } else {
            return 'В работе';
          }
          break;
        }
      }
    }
    if (row._type === 'NationalProject') {
      switch (i) {
        case 0: {
          return row.name;
          break;
        }
      }
    }
    return '';
  }

  public getTdClass(row:any, i:number):string {
    let prefix:string = '';
    switch (i) {
      case 0: {
        if (row._type === 'Protocol') {
          return prefix + ' p30';
        }
        return row.parentId == null ? prefix + ' p10' : prefix + ' p20';
        break;
      }
    }
    return prefix;
  }
  public getTrClass(row:any):string {
    if (row._type === 'Protocol') {
      if (row.completed) {
        return 'colored-row-green';
      } else if (row.daysToDue < 0) {
        return 'colored-row-red';
      } else if (row.daysToDue >= 0) {
        return 'colored-row';
      }
      return '';
    } else {
      return 'colored-row';
    }
  }
  public format(input:string):string {
    return input.slice(8, 10) + '.' + input.slice(5, 7) + '.' + input.slice(0, 4);
  }
  public getPages():number {
    return this.national_project_titles.length;
  }
  public pagesToText(i:number):string {
    return this.national_project_titles[i].name;
  }
}
