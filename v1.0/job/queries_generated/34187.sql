WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS movie_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movies,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(*) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    GROUP BY 
        ci.person_id
),
movie_keywords AS (
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
company_info AS (
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
enhanced_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.release_year, 'Unknown') AS production_year,
        mk.keywords,
        ci.companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        company_info ci ON m.id = ci.movie_id
)

SELECT 
    an.name AS actor_name,
    eh.title,
    eh.production_year,
    eh.keywords,
    eh.companies,
    ah.movie_count,
    ah.actor_rank
FROM 
    actor_hierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    enhanced_movie_info eh ON ci.movie_id = eh.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
WHERE 
    eh.production_year::integer >= 2000
    AND an.name IS NOT NULL
ORDER BY 
    ah.actor_rank, eh.production_year DESC;

-- Benchmarking performance with a focus on capturing comprehensive data related
-- to movies, actors, and their associations in the domain of film.
