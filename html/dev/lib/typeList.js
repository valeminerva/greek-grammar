import React from 'react';
import R from 'ramda';
import { labelNumber } from './labelNumber.js';
import { Panel } from 'react-bootstrap';

const kindsToClassName = new Map([
  ['Word Stage', 'typeKindWordStage'],
  ['Word Stage Transition', 'typeKindWordStageTransition'],
  ['Word Stage Part Transition', 'typeKindWordStagePartTransition'],
  ['Word Stage Part', 'typeKindWordStagePart'],
  ['Word Property', 'typeKindWordProperty'],
  ['Work Property', 'typeKindWorkProperty'],
  ['Composite Property', 'typeKindCompositeProperty']
]);

const TypeInfo = ({ title, kind, values, url }) => {
  const instanceCount = R.compose(R.sum, R.map(x => x.i))(values);
  return (
    <div className={kindsToClassName.get(kind)}>
      <a href={url}>{title}</a>
      <span className="typeKind"> &mdash; {kind} &mdash; </span>
      &ensp;
      <span className="typeInfoCounts">{labelNumber(values.length, 'value', 'values')}, {labelNumber(instanceCount, 'instance', 'instances')}</span>
    </div>
  );
};

const Stage = ({ stage, types, getTypeUrl }) => {
  const indexedPartTypes = R.map (x => ({ index: x, type: types[x] })) (stage.parts);

  return (
    <Panel header={types[stage.primary].title}>
      <TypeInfo {...types[stage.primary]} url={getTypeUrl(stage.primary)} />

      { R.map (x => (<TypeInfo key={x.index} {...x.type} url={getTypeUrl(x.index)} />)) (indexedPartTypes) }
    </Panel>
  );
};

const WordProperties = ({ typeIndexes, types, getTypeUrl }) => {
  const wordTypes = R.compose
    ( R.reverse
    , R.map (x => ({ index: x, type: types[x] }))
    )
    (typeIndexes);

  return (
    <Panel header="Word Properties" bsStyle="primary">
      { R.map (x => (<TypeInfo key={x.index} {...x.type} url={getTypeUrl(x.index)} />)) (wordTypes) }
    </Panel>
  );
}

export const TypeList = ({ stages, types, getTypeUrl }) => {
  const indexedStages = R.addIndex(R.map) ((x, i) => ({ index: i, stage: x })) (stages);
  const orderedStages = R.reverse(indexedStages);
  const wordPropertyTypeIndexes = R.compose
    ( R.map(x => x.index)
    , R.filter(x => x.isWordProperty)
    , R.addIndex(R.map) ((x, i) => ({ index: i, isWordProperty: x.kind === 'Word Property' }))
    )
    (types);
  return (
    <div className="listContainer">
      <WordProperties typeIndexes={wordPropertyTypeIndexes} types={types} getTypeUrl={getTypeUrl} />
      { R.map(x => <Stage key={x.index} stage={x.stage} types={types} getTypeUrl={getTypeUrl} />) (orderedStages) }
    </div>
  );
};
