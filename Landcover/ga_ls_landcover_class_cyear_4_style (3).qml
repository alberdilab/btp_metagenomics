<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" version="3.28.5-Firenze" minScale="1e+08" styleCategories="AllStyleCategories" hasScaleBasedVisibilityFlag="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
    <Private>0</Private>
  </flags>
  <temporal mode="0" enabled="0" fetchMode="0">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <elevation enabled="0" zscale="1" symbology="Line" zoffset="0" band="1">
    <data-defined-properties>
      <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
      </Option>
    </data-defined-properties>
    <profileLineSymbol>
      <symbol is_animated="0" name="" alpha="1" clip_to_extent="1" frame_rate="10" type="line" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option value="0" name="align_dash_pattern" type="QString"/>
            <Option value="square" name="capstyle" type="QString"/>
            <Option value="5;2" name="customdash" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
            <Option value="MM" name="customdash_unit" type="QString"/>
            <Option value="0" name="dash_pattern_offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
            <Option value="0" name="draw_inside_polygon" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="152,125,183,255" name="line_color" type="QString"/>
            <Option value="solid" name="line_style" type="QString"/>
            <Option value="0.6" name="line_width" type="QString"/>
            <Option value="MM" name="line_width_unit" type="QString"/>
            <Option value="0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0" name="ring_filter" type="QString"/>
            <Option value="0" name="trim_distance_end" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
            <Option value="MM" name="trim_distance_end_unit" type="QString"/>
            <Option value="0" name="trim_distance_start" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
            <Option value="MM" name="trim_distance_start_unit" type="QString"/>
            <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
            <Option value="0" name="use_custom_dash" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileLineSymbol>
    <profileFillSymbol>
      <symbol is_animated="0" name="" alpha="1" clip_to_extent="1" frame_rate="10" type="fill" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale" type="QString"/>
            <Option value="152,125,183,255" name="color" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,255" name="outline_color" type="QString"/>
            <Option value="no" name="outline_style" type="QString"/>
            <Option value="0.26" name="outline_width" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="solid" name="style" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileFillSymbol>
  </elevation>
  <customproperties>
    <Option type="Map">
      <Option value="false" name="WMSBackgroundLayer" type="bool"/>
      <Option value="false" name="WMSPublishDataSourceUrl" type="bool"/>
      <Option value="0" name="embeddedWidgets/count" type="int"/>
      <Option value="Value" name="identify/format" type="QString"/>
    </Option>
  </customproperties>
  <pipe-data-defined-properties>
    <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
    </Option>
  </pipe-data-defined-properties>
  <pipe>
    <provider>
      <resampling zoomedInResamplingMethod="nearestNeighbour" zoomedOutResamplingMethod="nearestNeighbour" maxOversampling="2" enabled="false"/>
    </provider>
    <rasterrenderer alphaBand="-1" opacity="1" nodataColor="" type="paletted" band="1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <colorPalette>
        <paletteEntry value="255" alpha="255" label="No Data" color="#FFFFFF"/>
        <paletteEntry value="1" alpha="255" label="Cultivated Terrestrial Vegetated" color="#97bb1a"/>
        <paletteEntry value="2" alpha="255" label="Cultivated Terrestrial Vegetated: Woody" color="#97bb1a"/>
        <paletteEntry value="3" alpha="255" label="Cultivated Terrestrial Vegetated: Herbaceous" color="#d1e033"/>
        <paletteEntry value="4" alpha="255" label="Cultivated Terrestrial Vegetated: Closed (greater than 65 %)" color="#c5a847"/>
        <paletteEntry value="5" alpha="255" label="Cultivated Terrestrial Vegetated: Open (40 to 65 %)" color="#cdb54b"/>
        <paletteEntry value="6" alpha="255" label="Cultivated Terrestrial Vegetated: Open (15 to 40 %)" color="#d5c14f"/>
        <paletteEntry value="7" alpha="255" label="Cultivated Terrestrial Vegetated: Sparse (4 to 15 %)" color="#e4d26c"/>
        <paletteEntry value="8" alpha="255" label="Cultivated Terrestrial Vegetated: Scattered (1 to 4 %)" color="#f2e38a"/>
        <paletteEntry value="9" alpha="255" label="Cultivated Terrestrial Vegetated: Woody Closed (greater than 65 %)" color="#c5a847"/>
        <paletteEntry value="10" alpha="255" label="Cultivated Terrestrial Vegetated: Woody Open (40 to 65 %)" color="#cdb54b"/>
        <paletteEntry value="11" alpha="255" label="Cultivated Terrestrial Vegetated: Woody Open (15 to 40 %)" color="#d5c14f"/>
        <paletteEntry value="12" alpha="255" label="Cultivated Terrestrial Vegetated: Woody Sparse (4 to 15 %)" color="#e4d26c"/>
        <paletteEntry value="13" alpha="255" label="Cultivated Terrestrial Vegetated: Woody Scattered (1 to 4 %)" color="#f2e38a"/>
        <paletteEntry value="14" alpha="255" label="Cultivated Terrestrial Vegetated: Herbaceous Closed (greater than 65 %)" color="#e4e034"/>
        <paletteEntry value="15" alpha="255" label="Cultivated Terrestrial Vegetated: Herbaceous Open (40 to 65 %)" color="#ebe854"/>
        <paletteEntry value="16" alpha="255" label="Cultivated Terrestrial Vegetated: Herbaceous Open (15 to 40 %)" color="#f2f07f"/>
        <paletteEntry value="17" alpha="255" label="Cultivated Terrestrial Vegetated: Herbaceous Sparse (4 to 15 %)" color="#f9f7ae"/>
        <paletteEntry value="18" alpha="255" label="Cultivated Terrestrial Vegetated: Herbaceous Scattered (1 to 4 %)" color="#fffede"/>
        <paletteEntry value="20" alpha="255" label="Natural Terrestrial Vegetated: Woody" color="#1ab157"/>
        <paletteEntry value="21" alpha="255" label="Natural Terrestrial Vegetated: Herbaceous" color="#5eb31f"/>
        <paletteEntry value="22" alpha="255" label="Natural Terrestrial Vegetated: Closed (greater than 65 %)" color="#0e7912"/>
        <paletteEntry value="23" alpha="255" label="Natural Terrestrial Vegetated: Open (40 to 65 %)" color="#2d8d2f"/>
        <paletteEntry value="24" alpha="255" label="Natural Terrestrial Vegetated: Open (15 to 40 %)" color="#50a052"/>
        <paletteEntry value="25" alpha="255" label="Natural Terrestrial Vegetated: Sparse (4 to 15 %)" color="#75b476"/>
        <paletteEntry value="26" alpha="255" label="Natural Terrestrial Vegetated: Scattered (1 to 4 %)" color="#9ac79c"/>
        <paletteEntry value="27" alpha="255" label="Natural Terrestrial Vegetated: Woody Closed (greater than 65 %)" color="#0e7912"/>
        <paletteEntry value="28" alpha="255" label="Natural Terrestrial Vegetated: Woody Open (40 to 65 %)" color="#2d8d2f"/>
        <paletteEntry value="29" alpha="255" label="Natural Terrestrial Vegetated: Woody Open (15 to 40 %)" color="#50a052"/>
        <paletteEntry value="30" alpha="255" label="Natural Terrestrial Vegetated: Woody Sparse (4 to 15 %)" color="#75b476"/>
        <paletteEntry value="31" alpha="255" label="Natural Terrestrial Vegetated: Woody Scattered (1 to 4 %)" color="#9ac79c"/>
        <paletteEntry value="32" alpha="255" label="Natural Terrestrial Vegetated: Herbaceous Closed (greater than 65 %)" color="#77a71e"/>
        <paletteEntry value="33" alpha="255" label="Natural Terrestrial Vegetated: Herbaceous Open (40 to 65 %)" color="#88b633"/>
        <paletteEntry value="34" alpha="255" label="Natural Terrestrial Vegetated: Herbaceous Open (15 to 40 %)" color="#99c450"/>
        <paletteEntry value="35" alpha="255" label="Natural Terrestrial Vegetated: Herbaceous Sparse (4 to 15 %)" color="#aad471"/>
        <paletteEntry value="36" alpha="255" label="Natural Terrestrial Vegetated: Herbaceous Scattered (1 to 4 %)" color="#bae292"/>
        <paletteEntry value="39" alpha="255" label="Cultivated Aquatic Vegetated: Herbaceous" color="#52e7ac"/>
        <paletteEntry value="40" alpha="255" label="Cultivated Aquatic Vegetated: Closed (greater than 65 %)" color="#2bd2cb"/>
        <paletteEntry value="41" alpha="255" label="Cultivated Aquatic Vegetated: Open (40 to 65 %)" color="#49ded8"/>
        <paletteEntry value="42" alpha="255" label="Cultivated Aquatic Vegetated: Open (15 to 40 %)" color="#6ee9e4"/>
        <paletteEntry value="43" alpha="255" label="Cultivated Aquatic Vegetated: Sparse (4 to 15 %)" color="#95f4f0"/>
        <paletteEntry value="44" alpha="255" label="Cultivated Aquatic Vegetated: Scattered (1 to 4 %)" color="#bbfffc"/>
        <paletteEntry value="50" alpha="255" label="Cultivated Aquatic Vegetated: Herbaceous Closed (greater than 65 %)" color="#52e7c4"/>
        <paletteEntry value="51" alpha="255" label="Cultivated Aquatic Vegetated: Herbaceous Open (40 to 65 %)" color="#71edd0"/>
        <paletteEntry value="52" alpha="255" label="Cultivated Aquatic Vegetated: Herbaceous Open (15 to 40 %)" color="#90f3dc"/>
        <paletteEntry value="53" alpha="255" label="Cultivated Aquatic Vegetated: Herbaceous Sparse (4 to 15 %)" color="#aff9e8"/>
        <paletteEntry value="54" alpha="255" label="Cultivated Aquatic Vegetated: Herbaceous Scattered (1 to 4 %)" color="#cffff4"/>
        <paletteEntry value="56" alpha="255" label="Natural Aquatic Vegetated: Woody" color="#128e94"/>
        <paletteEntry value="57" alpha="255" label="Natural Aquatic Vegetated: Herbaceous" color="#70ea86"/>
        <paletteEntry value="58" alpha="255" label="Natural Aquatic Vegetated: Closed (greater than 65 %)" color="#19ad6d"/>
        <paletteEntry value="59" alpha="255" label="Natural Aquatic Vegetated: Open (40 to 65 %)" color="#35b884"/>
        <paletteEntry value="60" alpha="255" label="Natural Aquatic Vegetated: Open (15 to 40 %)" color="#5dc39b"/>
        <paletteEntry value="61" alpha="255" label="Natural Aquatic Vegetated: Sparse (4 to 15 %)" color="#87ceb2"/>
        <paletteEntry value="62" alpha="255" label="Natural Aquatic Vegetated: Scattered (1 to 4 %)" color="#b0dac9"/>
        <paletteEntry value="63" alpha="255" label="Natural Aquatic Vegetated: Woody Closed (greater than 65 %)" color="#19ad6d"/>
        <paletteEntry value="64" alpha="255" label="Natural Aquatic Vegetated: Woody Closed (greater than 65 %) Water greater than 3 months (semi-) permenant" color="#19ad6d"/>
        <paletteEntry value="65" alpha="255" label="Natural Aquatic Vegetated: Woody Closed (greater than 65 %) Water less than 3 months (temporary or seasonal)" color="#19ad6d"/>
        <paletteEntry value="66" alpha="255" label="Natural Aquatic Vegetated: Woody Open (40 to 65 %)" color="#35b884"/>
        <paletteEntry value="67" alpha="255" label="Natural Aquatic Vegetated: Woody Open (40 to 65 %) Water greater than 3 months (semi-) permenant" color="#35b884"/>
        <paletteEntry value="68" alpha="255" label="Natural Aquatic Vegetated: Woody Open (40 to 65 %) Water less than 3 months (temporary or seasonal)" color="#35b884"/>
        <paletteEntry value="69" alpha="255" label="Natural Aquatic Vegetated: Woody Open (15 to 40 %)" color="#5dc39b"/>
        <paletteEntry value="70" alpha="255" label="Natural Aquatic Vegetated: Woody Open (15 to 40 %) Water greater than 3 months (semi-) permenant" color="#5dc39b"/>
        <paletteEntry value="71" alpha="255" label="Natural Aquatic Vegetated: Woody Open (15 to 40 %) Water less than 3 months (temporary or seasonal)" color="#5dc39b"/>
        <paletteEntry value="72" alpha="255" label="Natural Aquatic Vegetated: Woody Sparse (4 to 15 %)" color="#87ceb2"/>
        <paletteEntry value="73" alpha="255" label="Natural Aquatic Vegetated: Woody Sparse (4 to 15 %) Water greater than 3 months (semi-) permenant" color="#87ceb2"/>
        <paletteEntry value="74" alpha="255" label="Natural Aquatic Vegetated: Woody Sparse (4 to 15 %) Water less than 3 months (temporary or seasonal)" color="#87ceb2"/>
        <paletteEntry value="75" alpha="255" label="Natural Aquatic Vegetated: Woody Scattered (1 to 4 %)" color="#b0dac9"/>
        <paletteEntry value="76" alpha="255" label="Natural Aquatic Vegetated: Woody Scattered (1 to 4 %) Water greater than 3 months (semi-) permenant" color="#b0dac9"/>
        <paletteEntry value="77" alpha="255" label="Natural Aquatic Vegetated: Woody Scattered (1 to 4 %) Water less than 3 months (temporary or seasonal)" color="#b0dac9"/>
        <paletteEntry value="78" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Closed (greater than 65 %)" color="#27cc8b"/>
        <paletteEntry value="79" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Closed (greater than 65 %) Water greater than 3 months (semi-) permenant" color="#27cc8b"/>
        <paletteEntry value="80" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Closed (greater than 65 %) Water less than 3 months (temporary or seasonal)" color="#27cc8b"/>
        <paletteEntry value="81" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Open (40 to 65 %)" color="#42d89f"/>
        <paletteEntry value="82" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Open (40 to 65 %) Water greater than 3 months (semi-) permenant" color="#42d89f"/>
        <paletteEntry value="83" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Open (40 to 65 %) Water less than 3 months (temporary or seasonal)" color="#42d89f"/>
        <paletteEntry value="84" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Open (15 to 40 %)" color="#63e3b4"/>
        <paletteEntry value="85" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Open (15 to 40 %) Water greater than 3 months (semi-) permenant" color="#63e3b4"/>
        <paletteEntry value="86" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Open (15 to 40 %) Water less than 3 months (temporary or seasonal)" color="#63e3b4"/>
        <paletteEntry value="87" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Sparse (4 to 15 %)" color="#87efc9"/>
        <paletteEntry value="88" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Sparse (4 to 15 %) Water greater than 3 months (semi-) permenant" color="#87efc9"/>
        <paletteEntry value="89" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Sparse (4 to 15 %) Water less than 3 months (temporary or seasonal)" color="#87efc9"/>
        <paletteEntry value="90" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Scattered (1 to 4 %)" color="#abfadd"/>
        <paletteEntry value="91" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Scattered (1 to 4 %) Water greater than 3 months (semi-) permenant" color="#abfadd"/>
        <paletteEntry value="92" alpha="255" label="Natural Aquatic Vegetated: Herbaceous Scattered (1 to 4 %) Water less than 3 months (temporary or seasonal)" color="#abfadd"/>
        <paletteEntry value="93" alpha="255" label="Artificial Surface" color="#da5c69"/>
        <paletteEntry value="95" alpha="255" label="Natural Surface: Sparsely vegetated" color="#ffe68c"/>
        <paletteEntry value="96" alpha="255" label="Natural Surface: Very sparsely vegetated" color="#fad26e"/>
        <paletteEntry value="97" alpha="255" label="Natural Surface: Bare areas, unvegetated" color="#f3ab69"/>
        <paletteEntry value="98" alpha="255" label="Water" color="#4d9fdc"/>
        <paletteEntry value="100" alpha="255" label="Water: Tidal area" color="#bbdce9"/>
        <paletteEntry value="101" alpha="255" label="Water: Perennial (greater than 9 months)" color="#1b55ba"/>
        <paletteEntry value="102" alpha="255" label="Water: Non-perennial (7 to 9 months)" color="#3479c9"/>
        <paletteEntry value="103" alpha="255" label="Water: Non-perennial (4 to 6 months)" color="#4f9dd9"/>
        <paletteEntry value="104" alpha="255" label="Water: Non-perennial (1 to 3 months)" color="#85cafd"/>
      </colorPalette>
      <colorramp name="[source]" type="randomcolors">
        <Option/>
      </colorramp>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0" gamma="1"/>
    <huesaturation grayscaleMode="0" colorizeOn="0" colorizeGreen="128" colorizeRed="255" colorizeBlue="128" saturation="0" colorizeStrength="100" invertColors="0"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
