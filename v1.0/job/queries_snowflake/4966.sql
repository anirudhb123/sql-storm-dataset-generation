
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 3
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tcm.title,
    tcm.production_year,
    tcm.cast_count,
    COALESCE(cd.companies, 'No Companies') AS companies,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = tcm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Country') 
     AND mi.info IS NOT NULL) AS country_info_count
FROM 
    TopCastMovies tcm
LEFT JOIN 
    CompanyData cd ON tcm.movie_id = cd.movie_id
ORDER BY 
    tcm.production_year DESC, 
    tcm.cast_count DESC;
