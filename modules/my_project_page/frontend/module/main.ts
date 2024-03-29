// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {APP_INITIALIZER, Injector, NgModule} from '@angular/core';
import {ChartsModule} from 'ng2-charts';
import {FormsModule} from "@angular/forms";
import {BrowserAnimationsModule} from "@angular/platform-browser/animations";
import {OpenProjectPluginContext} from 'core-app/modules/plugins/plugin-context';
import {OverviewResource} from './hal/resources/overview-resource';
import {multiInput} from 'reactivestates';
import {HookService} from "../../hook-service";
import {WorkPackageOverviewStatusDiagramComponent} from "./wp-diagram/wp-overview-status-diagram.component";
import {WorkPackageOverviewDateDiagramComponent} from "./wp-diagram/wp-overview-date-diagram.component";



export function initializeMyProjectPagePlugin(injector:Injector) {
    return () => {
        window.OpenProject.getPluginContext()
            .then((pluginContext:OpenProjectPluginContext) => {
                let halResourceService = pluginContext.services.halResource;
                halResourceService.registerResource('Overview', { cls: OverviewResource });

                let states = pluginContext.services.states;
                states.add('overviews', multiInput<OverviewResource>());
            });
        const hookService = injector.get(HookService);
        hookService.register('openProjectAngularBootstrap', () => {
            return [
                { selector: 'wp-overview-status-diagram', cls: WorkPackageOverviewStatusDiagramComponent },
                { selector: 'wp-overview-date-diagram', cls: WorkPackageOverviewDateDiagramComponent }
            ];
        });
    };
}

@NgModule({
    imports: [
      ChartsModule,
      FormsModule,
      BrowserAnimationsModule
    ],
    declarations: [
        WorkPackageOverviewStatusDiagramComponent,
        WorkPackageOverviewDateDiagramComponent
    ],
    providers: [
        { provide: APP_INITIALIZER, useFactory: initializeMyProjectPagePlugin, deps: [Injector], multi: true },
    ],
    entryComponents: [
        WorkPackageOverviewStatusDiagramComponent,
        WorkPackageOverviewDateDiagramComponent
    ]
})
export class PluginModule {
}
