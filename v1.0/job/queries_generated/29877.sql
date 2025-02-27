WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 3
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.actor_count, rm.actor_names
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.actor_count,
    mwk.actor_names,
    mwk.keywords,
    count(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mc ON mwk.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    mwk.movie_id, mwk.title, mwk.production_year, mwk.actor_count, mwk.actor_names
ORDER BY 
    mwk.production_year DESC, mwk.actor_count DESC
LIMIT 10;
