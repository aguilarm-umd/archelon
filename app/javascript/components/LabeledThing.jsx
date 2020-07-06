import React from "react"
import PropTypes from "prop-types"
import URIRef from "./URIRef";
import PlainLiteral from "./PlainLiteral";

const labelPredicate = 'http://www.w3.org/2000/01/rdf-schema#label';
const sameAsPredicate = 'http://www.w3.org/2002/07/owl#sameAs';

const defaultGraph = {}
defaultGraph[labelPredicate] = [{ '@value': '', '@language': '' }]
defaultGraph[sameAsPredicate] = [{ '@id': '' }]

function getSingleNode(graph, predicate) {
  let node = graph.hasOwnProperty(predicate) ? graph[predicate] : defaultGraph[predicate];
  return (node instanceof Array) ? node[0] : node;
}

class LabeledThing extends React.Component {
  constructor(props) {
    super(props);
    this.subject = props.value['@id'];
    this.state = {
      label: getSingleNode(props.obj, labelPredicate),
      sameAs: getSingleNode(props.obj, sameAsPredicate)
    };
  }
  render () {
    let fieldName = `${this.props.paramPrefix}[${this.props.name}][][@id]`
    return (
        <React.Fragment>
          <input type="hidden" name={fieldName} value={this.subject}/>
          <PlainLiteral paramPrefix={this.subject} name={labelPredicate} value={this.state.label}/>
          &nbsp;URI:&nbsp;
          <URIRef paramPrefix={this.subject} name={sameAsPredicate} value={this.state.sameAs}/>
        </React.Fragment>
    );
  }
}

LabeledThing.propTypes = {
  /**
   * The name of the element, used to with `paramPrefix` to construct the
   * parameter sent via the form submission.
   */
  name: PropTypes.string,
  /**
   * Combined with the name (`<paramPrefix>[<name>][]`) to construct the
   * parameter sent via the form submission.
   */
  paramPrefix: PropTypes.string,
  /**
   * The subject URI of the embedded object, as `{"@id": "..."}`
   */
  value: PropTypes.object,
  /**
   * The graph for the embedded object
   */
  obj: PropTypes.object
}

LabeledThing.defaultProps = {
  value: { '@id': '' },
  obj: defaultGraph
}

export default LabeledThing
