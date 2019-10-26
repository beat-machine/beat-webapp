export let effectDefinitions = [
  {
    id: "remove",
    name: "Remove",
    description: "Removes beats entirely.",
    params: [
      {
        id: "period",
        name: "Every",
        default: 2,
        minimum: 2
      }
    ],
    validate: () => null,
    serialize: paramObj => paramObj
  },
  {
    id: "swap",
    name: "Swap",
    description: "Swaps two beats throughout the entire song.",
    params: [
      {
        id: "x_period",
        name: "First Beat",
        default: 2,
        minimum: 1
      },
      {
        id: "y_period",
        name: "Second Beat",
        default: 4,
        minimum: 1
      },
      {
        id: "group_size",
        name: "Beats/Measure",
        default: 4,
        minimum: 2
      }
    ],
    validate(paramObj) {
      if (paramObj["x_period"] === paramObj["y_period"]) {
        return "Both beats are the same. Try changing one of them.";
      }

      if (
        paramObj["x_period"] > paramObj["group_size"] ||
        paramObj["y_period"] > paramObj["group_size"]
      ) {
        return "One or both beat numbers are too high. Try increasing the beats per measure or decreasing the beat numbers.";
      }

      return null;
    },
    serialize: paramObj => paramObj
  },
  {
    id: "cut",
    name: "Cut",
    description: "Cuts beats into 2+ pieces.",
    params: [
      {
        id: "period",
        name: "Every",
        default: 2,
        minimum: 1
      },
      {
        id: "denominator",
        name: "Pieces",
        default: 2,
        minimum: 2,
        help: "Number of pieces to cut each beat into."
      },
      {
        id: "take_index",
        name: "Take Piece #",
        default: 1,
        minimum: 1,
        help: "Piece of the cut beat to use."
      }
    ],
    validate(paramObj) {
      if (paramObj["take_index"] > paramObj["denominator"]) {
        return (
          `Can't take piece #` +
          paramObj["take_index"] +
          ` of a beat that's only being divided into ` +
          paramObj["denominator"] +
          ` parts.`
        );
      }

      return null;
    },
    serialize: paramObj => {
      return { ...paramObj, take_index: paramObj["take_index"] - 1 };
    }
  },
  {
    id: "repeat",
    name: "Repeat",
    description: "Repeats beats a certain number of times.",
    params: [
      {
        id: "period",
        name: "Every",
        default: 2,
        minimum: 1
      },
      {
        id: "times",
        name: "Times",
        default: 2,
        minimum: 1
      }
    ],
    validate: () => null,
    serialize: paramObj => paramObj
  },
  {
    id: "silence",
    name: "Silence",
    description: "Silences beats, but retains their length.",
    params: [
      {
        id: "period",
        name: "Every",
        default: 2,
        minimum: 2
      }
    ],
    validate: () => null,
    serialize: paramObj => paramObj
  },
  {
    id: "reverse",
    name: "Reverse",
    description: "Reverses beats.",
    params: [
      {
        id: "period",
        name: "Every",
        default: 2,
        minimum: 1
      }
    ],
    validate: () => null,
    serialize: paramObj => paramObj
  },
  {
    id: "randomize",
    name: "Randomize",
    description:
      "Totally randomizes all beats. It's terrible. You don't want this.",
    params: [],
    validate: () => null,
    serialize: paramObj => paramObj
  }
];
