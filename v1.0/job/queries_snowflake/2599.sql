
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
movies_with_actor_counts AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        actor_counts ac ON m.id = ac.movie_id
    WHERE 
        m.production_year >= 2000
        AND m.title IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    mt.actor_count,
    rk.title_rank,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords
FROM 
    movies_with_actor_counts mt
JOIN 
    ranked_titles rk ON mt.movie_id = rk.title_id
LEFT JOIN 
    movie_keywords mk ON mt.movie_id = mk.movie_id
WHERE 
    mt.actor_count >= 3
    AND ((mt.production_year % 2 = 0 AND mt.actor_count < 10) OR 
         (mt.production_year % 2 != 0 AND mt.actor_count >= 5))
ORDER BY 
    mt.production_year DESC, 
    mt.actor_count DESC;
