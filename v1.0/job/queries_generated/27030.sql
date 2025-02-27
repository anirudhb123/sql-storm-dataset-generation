WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(an.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        at.production_year >= 1990 -- Considering movies from 1990 onwards
    GROUP BY 
        at.id, at.title, at.production_year
),
SelectedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actors
    FROM 
        RankedMovies
    WHERE 
        rn <= 5 -- Selecting top 5 movies per production year
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.cast_count,
    sm.actors,
    kt.kind AS movie_kind,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies
FROM 
    SelectedMovies sm
LEFT JOIN 
    movie_companies mc ON sm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    kind_type kt ON mc.company_type_id = kt.id
GROUP BY 
    sm.movie_id, sm.movie_title, sm.production_year, sm.cast_count, kt.kind
ORDER BY 
    sm.production_year DESC, sm.cast_count DESC;

This query processes string data with a focus on movie titles, actors, and associated companies, delivering a ranked output that succinctly represents movie benchmark data.
