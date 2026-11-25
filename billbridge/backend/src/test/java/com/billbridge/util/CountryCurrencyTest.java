package com.billbridge.util;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class CountryCurrencyTest {

    @ParameterizedTest
    @CsvSource({"NP,NPR", "np,NPR", "US,USD", "IN,INR", "DE,EUR", "FR,EUR", "GB,GBP", "JP,JPY", "BD,BDT"})
    void mapsCountryToItsCurrency(String country, String currency) {
        assertThat(CountryCurrency.currencyFor(country)).contains(currency);
    }

    @ParameterizedTest
    @CsvSource({"ZZ", "XX", "AQ", "''"})
    void rejectsUnknownCountriesAndTerritoriesWithoutCurrency(String country) {
        assertThat(CountryCurrency.currencyFor(country)).isEqualTo(Optional.empty());
    }

    @Test
    void nullIsNotAValidCountry() {
        assertThat(CountryCurrency.isValidCountry(null)).isFalse();
        assertThat(CountryCurrency.currencyFor(null)).isEmpty();
    }
}
