WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
actor_movie_counts AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(amc.movie_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    r.rank
FROM 
    ranked_movies r
LEFT JOIN 
    actor_movie_counts amc ON r.movie_id = amc.actor_id
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
WHERE 
    (r.production_year >= 2000 AND r.production_year <= 2023)
    AND (r.rank <= 5 OR mk.keywords IS NOT NULL)
ORDER BY 
    r.production_year DESC, 
    r.rank;
