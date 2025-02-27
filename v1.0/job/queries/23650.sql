WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        mi.info AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating' LIMIT 1)
    WHERE 
        rm.rank_year <= 10
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.production_year,
        mw.cast_count,
        COALESCE(mw.additional_info, 'No Info Available') AS additional_info,
        COALESCE(tc.companies, 'No Companies Listed') AS companies
    FROM 
        MoviesWithInfo mw
    LEFT JOIN 
        TopCompanies tc ON mw.movie_id = tc.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.additional_info,
    fr.companies,
    CASE 
        WHEN fr.cast_count IS NULL THEN 'Unknown'
        WHEN fr.cast_count > 20 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN fr.additional_info LIKE '%Award%' THEN 'Award-winning' 
        ELSE 'Not Award-winning' 
    END AS award_status,
    (SELECT AVG(cast_count) FROM MoviesWithInfo) AS avg_cast_count,
    (SELECT COUNT(DISTINCT production_year) FROM aka_title) AS distinct_years
FROM 
    FinalResults fr
WHERE 
    fr.production_year > 2000
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC
LIMIT 50;
