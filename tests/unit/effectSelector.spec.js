import EffectSelector from "@/components/EffectSelector.vue";
import { shallowMount } from "@vue/test-utils";

const sampleEffects = [
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
    id: "test",
    name: "Test Effect",
    description: "Does nothing. Param 1 can't equal Param 2.",
    params: [
      {
        id: "param1",
        name: "Param 1",
        default: 0,
        minimum: 0
      },
      {
        id: "param2",
        name: "Param 2",
        default: 2,
        minimum: 0
      }
    ],
    validate: paramObj => {
      if (paramObj["param1"] === paramObj["param2"]) {
        return "param1 === param2";
      }

      return null;
    },
    serialize: paramObj => paramObj
  }
];

function createWrapperWithSampleEffects() {
  return shallowMount(EffectSelector, {
    propsData: {
      effects: sampleEffects
    }
  });
}

describe("EffectSelector.vue", () => {
  it("defaults to no effect when no data is given", () => {
    const defaultData = EffectSelector.data();
    expect(defaultData.selectedEffectIndex).toBe(0);
    expect(defaultData.currentParams).toEqual({});
    expect(defaultData.valid).toBeTruthy();
    expect(defaultData.validationError).toBeFalsy();
  });

  it("renders the correct number of fields for an effect on load", () => {
    const wrapper = createWrapperWithSampleEffects();
    expect(wrapper.findAll("input").length).toBe(1);
  });

  it("applies default values from effect definitions on load", () => {
    const wrapper = createWrapperWithSampleEffects();
    expect(wrapper.find("input").element.value).toBe("2");
  });

  it("applies lower bounds from effect definitions on load", () => {
    const wrapper = createWrapperWithSampleEffects();
    expect(wrapper.find("input").element.min).toBe("2");
  });

  it("renders the correct number of fields for an effect on change", () => {
    const wrapper = createWrapperWithSampleEffects();
    wrapper.find("select").setValue("1");
    expect(wrapper.findAll("input").length).toBe(2);
  });

  it("applies lower bounds from effect definitions on change", () => {
    const wrapper = createWrapperWithSampleEffects();
    wrapper.find("select").setValue(1);
    let inputs = wrapper.findAll("input");
    expect(inputs.at(0).element.min).toBe("0");
    expect(inputs.at(1).element.min).toBe("0");
  });

  it("does not persist parameter values on effect change", () => {
    const wrapper = createWrapperWithSampleEffects();
    wrapper.find("input").setValue(100);
    wrapper.find("select").setValue(1);
    expect(wrapper.find("input").element.value).not.toBe("100");
    wrapper.find("select").setValue(0);
    expect(wrapper.find("input").element.value).not.toBe("100");
  });

  it("doesn't display an error when a parameter's validation function succeeds", () => {
    const wrapper = createWrapperWithSampleEffects();
    expect(wrapper.find(".error").exists()).toBeFalsy();
  });

  it("displays an error when a parameter's validation function fails", () => {
    const wrapper = createWrapperWithSampleEffects();
    wrapper.find("select").setValue(1);
    let inputs = wrapper.findAll("input");
    inputs.at(0).setValue(10);
    inputs.at(1).setValue(10);
    expect(wrapper.find(".error").exists()).toBeTruthy();
  });
});
