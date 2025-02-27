WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    mc.company_names,
    mc.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.id = mc.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 100;
