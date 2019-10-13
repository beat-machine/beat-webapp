import EffectSelector from '@/components/EffectSelector.vue'

describe('EffectSelector.vue', () => {
  it('defaults to no effect', () => {
    const defaultData = EffectSelector.data()
    expect(defaultData.selectedEffectIndex).toBe(0)
    expect(defaultData.currentParams).toEqual({})
    expect(defaultData.valid).toBeTruthy()
    expect(defaultData.validationError).toBeFalsy()
  })
})
