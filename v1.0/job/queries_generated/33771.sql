WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        1 AS level
    FROM 
        cast_info c
    GROUP BY 
        c.person_id

    UNION ALL

    SELECT 
        c.person_id,
        ah.total_movies + COUNT(DISTINCT c.movie_id) AS total_movies,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        actor_hierarchy ah ON c.person_id = ah.person_id
    GROUP BY 
        c.person_id, ah.total_movies, ah.level
),
movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        a.name AS actor_name,
        count(c.role_id) AS roles_count,
        m.production_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, a.name, m.production_year
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mc.movie_id,
    mc.title,
    mc.actor_name,
    mc.roles_count,
    mc.production_year,
    ks.keywords,
    ks.keyword_count,
    ah.total_movies AS actor_total_movies,
    COALESCE(
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY mc.roles_count DESC),
        0
    ) AS rank_in_movie,
    CASE 
        WHEN mc.production_year IS NULL THEN 'Unknown Year'
        WHEN mc.production_year < 2000 THEN 'Before 2000'
        ELSE 'After 2000'
    END AS period
FROM 
    movie_cast mc
LEFT JOIN 
    keyword_summary ks ON mc.movie_id = ks.movie_id
LEFT JOIN 
    actor_hierarchy ah ON mc.actor_name = ah.person_id
WHERE 
    mc.production_year IS NOT NULL
ORDER BY 
    mc.roles_count DESC, mc.title ASC;
