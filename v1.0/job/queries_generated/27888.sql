WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actors
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
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
        rm.movie_id, rm.movie_title, rm.production_year, rm.actor_count, rm.actor_names
)
SELECT 
    mwk.movie_id,
    mwk.movie_title,
    mwk.production_year,
    mwk.actor_count,
    mwk.actor_names,
    mwk.keywords,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mc ON mwk.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mwk.actor_count >= 5
GROUP BY 
    mwk.movie_id, mwk.movie_title, mwk.production_year, mwk.actor_count, mwk.actor_names
ORDER BY 
    mwk.production_year DESC, mwk.actor_count DESC;
