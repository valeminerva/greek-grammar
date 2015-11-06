import R from 'ramda';
import * as Action from "./action.js"

export const view = R.compose(R.fromPairs, R.map(x => [x,x])) ([
  'loadingIndex',
  'loadingWork',
  'workList',
  'typeList',
  'work',
  'valueList',
  'loadingValues',
]);

export const initial = {
  visual: {
    view: view.loadingIndex,
  },
  data: {
    works: new Map(),
    types: new Map(),
  },
};

export function hasWork(state, workIndex) { return state.data.works.has(workIndex); }
export function hasValues(state, typeIndex) { return state.data.types.has(typeIndex); }

function updateMap(map, key, value) {
  const newMap = new Map(map);
  newMap.set(key, value);
  return newMap;
}

export function applyAction(state = {}, action) {
  const data = getData(state.data, action);
  const visual = getVisual(action);

  return { data, visual };
}

export const getVisual = action => {
  switch (action.type) {
    case Action.types.requestIndex: return { view: view.loadingIndex };
    case Action.types.receiveIndex: return { view: view.workList };
    case Action.types.viewWorkList: return { view: view.workList };
    case Action.types.viewTypeList: return { view: view.typeList };
    case Action.types.requestWork: return { view: view.loadingWork, workIndex: action.workIndex };
    case Action.types.receiveWork: return { view: view.loadingWork, workIndex: action.workIndex };
    case Action.types.viewWork: return { view: view.work, workIndex: action.workIndex };
    case Action.types.viewValueList: return { view: view.valueList, typeIndex: action.typeIndex };
    case Action.types.requestValues: return { view: view.loadingValues, typeIndex: action.typeIndex };
    case Action.types.receiveValues: return { view: view.loadingValues, typeIndex: action.typeIndex };
    default: console.log('Unknown action', action); return {};
  }
};

const getData = (data, action) => {
  switch (action.type) {
    case Action.types.requestIndex: return { ...data, index: { loading: true } };
    case Action.types.receiveIndex: return { ...data, index: action.index };
    case Action.types.requestWork: return { ...data, works: updateMap(data.works, action.workIndex, { loading: true }) };
    case Action.types.receiveWork: return { ...data, works: updateMap(data.works, action.workIndex, action.work) };
    case Action.types.requestValues: return { ...data, types: updateMap(data.types, action.typeIndex, { loading: true }) };
    case Action.types.receiveValues: return { ...data, types: updateMap(data.types, action.typeIndex, action.typeValues) };
    default: return data;
  }
};

export const getActionForVisual = visual => {
  if (visual.view === view.workList)
    return Action.fetchViewWorkList();
  if (visual.view === view.typeList)
    return Action.fetchViewTypeList();
  if (visual.view === view.work && !R.isNil(visual.workIndex))
    return Action.fetchViewWork(visual.workIndex);
  if (visual.view === view.valueList && !R.isNil(visual.typeIndex))
    return Action.fetchViewValueList(visual.typeIndex);
  else
    return undefined;
}
