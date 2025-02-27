WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY c.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
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
movie_info_aggregate AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ki.keywords, 'No Keywords') AS keywords,
        COALESCE(a.actor_count, 0) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keywords ki ON m.id = ki.movie_id
    LEFT JOIN 
        movie_actors a ON m.id = a.movie_id
    WHERE 
        m.production_year >= 2000
        AND LENGTH(m.title) > 10
        AND (a.actor_rank IS NULL OR a.actor_rank < 5)
)
SELECT 
    ma.movie_id,
    ma.title,
    ma.keywords,
    ma.actor_count,
    CASE 
        WHEN ma.actor_count > 0 THEN 'Has Actors'
        ELSE 'No Actors'
    END AS actor_presence,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ma.movie_id) AS info_count,
    (SELECT STRING_AGG(note, '; ') FROM movie_info mi WHERE mi.movie_id = ma.movie_id AND mi.note IS NOT NULL) AS notes
FROM 
    movie_info_aggregate ma
WHERE 
    ma.actor_count >= (SELECT AVG(actor_count) FROM movie_info_aggregate) 
    OR ma.keywords LIKE '%Action%'
ORDER BY 
    ma.actor_count DESC, 
    ma.title;
