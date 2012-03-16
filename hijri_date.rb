#!/usr/bin/ruby

# hijri_date.rb
# Murtaza Gulamali (18/08/2011)
#
# A Ruby class to store Hijri dates as well as convert them to/from Astronomical Julian Date.
# eg. to return Hijri date for today
#   gregorian_date = Date.today
#   hijri_date = HijriDate.from_ajd(gregorian_date.ajd)
#   puts "Today is #{hijri_date.to_s}"
#
# This software is released under the terms and conditions of The MIT License:
# http://www.opensource.org/licenses/mit-license.php

require 'date'

class HijriDate
    # create setters and getters
    attr_accessor :year, :month, :day

    # Hijri month names
    MONTHNAMES = [nil,
                  'Moharram al-Haraam',
                  'Safar al-Muzaffar',
                  'Rabi al-Awwal',
                  'Rabi al-Aakhar',
                  'Jumada al-Ula',
                  'Jumada al-Ukhra',
                  'Rajab al-Asab',
                  'Shabaan al-Karim',
                  'Ramadaan al-Moazzam',
                  'Shawwal al-Mukarram',
                  'Zilqadah al-Haraam',
                  'Zilhaj al-Haraam']
    
    # short form of Hijri month names
    SHORTMONTHNAMES = [nil,
                       'Moharram',
                       'Safar',
                       'Rabi I',
                       'Rabi II',
                       'Jumada I',
                       'Jumada II',
                       'Rajab',
                       'Shabaan',
                       'Ramadaan',
                       'Shawwal',
                       'Zilqadah',
                       'Zilhaj']
    
    # number of days in the year per month
    DAYSINYEAR = [30, 59, 89, 118, 148, 177, 207, 236, 266, 295, 325, 355]
    
    # number of days in 30-years, per year
    DAYSIN30YEARS = [ 354,  708, 1063, 1417, 1771, 2126, 2480, 2834,  3189,  3543,
                     3898, 4252, 4606, 4961, 5315, 5669, 6024, 6378,  6732,  7087,
                     7441, 7796, 8150, 8504, 8859, 9213, 9567, 9922, 10276, 10631]

    # constructor
    def initialize(year = 1432, month = 6 , day = 20)
        @year = year
        @month = month
        @day = day
    end
    
    # convert to string object
    def to_s(date = self)
        return "#{date.day} #{HijriDate::MONTHNAMES[date.month]} #{date.year}H"
    end
    
    # is this (or the specified) year a Kabisa year?
    def is_kabisa?(year = self.year)
        for i in [2, 5, 8, 10, 13, 16, 19, 21, 24, 27, 29]
            if (year%30==i)
                return true
            end
        end
        return false
    end
    
    # number of days in this (or the specified) month and year
    def days_in_month(month = self.month, year = self.year)
        if ((month==12) and (is_kabisa?(year))) or (month%2==1)
            return 30
        end
        return 29           
    end

    # day of the year corresponding to this (or specified) Hijri date   
    def day_of_year(date = self)
        if date.month==1
            return date.day
        end
        return HijriDate::DAYSINYEAR[date.month-2] + date.day
    end
    
    # return Astronomical Julian Day number associated with this (or specified) Hijri date
    def ajd(date = self)
        y30 = (date.year/30.0).floor
        if (date.year%30 == 0)
            return 1948083.5 + y30*10631 + day_of_year(date)
        else
            return 1948083.5 + y30*10631 + HijriDate::DAYSIN30YEARS[date.year-y30*30-1] + day_of_year(date)
        end
    end
    
    # return new Hijri Date object associated with specified Astronomical Julian Day number
    def HijriDate.from_ajd(ajd = 1948083.5)
        left = (ajd - 1948083.5).to_i
        y30 = (left/10631.0).floor
        left -= y30*10631
        i = 0
        while left > HijriDate::DAYSIN30YEARS[i]
            i += 1
        end
        year = (y30*30.0 + i).to_i
        if i>0
            left -= HijriDate::DAYSIN30YEARS[i-1]
        end
        i = 0
        while left > HijriDate::DAYSINYEAR[i]
            i += 1
        end
        month = (i+1).to_i
        if i>0
            day = (left - HijriDate::DAYSINYEAR[i-1]).to_i
        else
            day = left.to_i
        end
        return HijriDate.new(year,month,day)
    end
    
    # return a new HijriDate object that is n days after the current one.
    def + (n)
        case n
            when Numeric; return HijriDate.from_ajd(self.ajd+n)
        end
        raise TypeError, 'expected numeric'
    end

    # return a new HijriDate object that is n days before the current one.
    def - (n)
        case n
            when Numeric; return HijriDate.from_ajd(self.ajd-n)
        end
        raise TypeError, 'expected numeric'
    end
end
