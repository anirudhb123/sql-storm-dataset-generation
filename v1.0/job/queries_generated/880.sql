WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FinalResult AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mc.cast_names, 'No cast') AS cast_names,
        COALESCE(comp.company_names, 'No companies') AS company_names
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCast mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        MovieCompanies comp ON m.movie_id = comp.movie_id
)

SELECT 
    *
FROM 
    FinalResult
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, title
LIMIT 100;
