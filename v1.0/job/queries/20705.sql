WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.id) AS actor_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ka.id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ka ON ka.person_id = c.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        p.id AS person_id,
        p.name,
        pi.info AS biography,
        RANK() OVER (PARTITION BY p.id ORDER BY pi.info_type_id) AS bio_rank
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.imdb_id = pi.person_id
    WHERE 
        p.gender = 'F'
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
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.actor_count,
    rm.has_note_count,
    mk.keywords,
    ai.name AS actress_name,
    ai.biography
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    actor_info ai ON rm.actor_count > 3 AND ai.bio_rank = 1
WHERE 
    rm.rank_per_year <= 3
    AND (mk.keywords IS NOT NULL OR mk.keywords LIKE '%thriller%')
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
