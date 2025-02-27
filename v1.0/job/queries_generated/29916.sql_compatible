
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),

KeywordMovies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

MovieCompanies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    km.keywords,
    cc.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
LEFT JOIN 
    MovieCompanies cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
