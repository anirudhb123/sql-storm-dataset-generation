WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        c.movie_id,
        COUNT(c.id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name, a.person_id, c.movie_id
    HAVING 
        COUNT(c.id) > 1
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.movies_count,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.movie_id 
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')) AS awards_count,
    COALESCE((SELECT STRING_AGG(kw.keyword, ', ') 
              FROM movie_keyword mk 
              JOIN keyword kw ON mk.keyword_id = kw.id 
              WHERE mk.movie_id = rm.movie_id), 'No keywords') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_details ad ON rm.movie_id = ad.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank, 
    ad.movies_count DESC;
