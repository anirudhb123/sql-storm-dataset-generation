
WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
actor_movie_info AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(aci.actor_count, 0) AS total_actors,
    COALESCE(aci.actor_names, '') AS actors,
    COALESCE(kc.keyword_count, 0) AS total_keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_movie_info aci ON rm.movie_id = aci.movie_id
LEFT JOIN 
    keyword_count kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    total_actors DESC;
