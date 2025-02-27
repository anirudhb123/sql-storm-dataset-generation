WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ka.id) AS aka_count,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        aka_name ka ON mk.keyword_id = ka.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.aka_count,
    rm.cast_count,
    rc.company_count,
    rc.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    RankedCompanies rc ON rm.movie_id = rc.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.title;
