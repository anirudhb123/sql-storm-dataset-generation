WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count_rank,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_names AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COALESCE(ac.name, 'Unknown Actor') AS character_name
    FROM 
        aka_name ak
    LEFT JOIN 
        char_name ac ON ak.person_id = ac.imdb_id
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
company_aggregate AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, '; ') AS companies,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    ak.actor_name,
    ak.character_name,
    mk.keywords,
    ca.companies,
    ca.company_count
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_names ak ON rm.movie_id = ak.person_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    company_aggregate ca ON rm.movie_id = ca.movie_id
WHERE 
    (rm.actor_count_rank = 1 OR (rm.actor_count_rank IS NULL))
    AND (rm.production_year >= 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC, rm.movie_id
LIMIT 100;