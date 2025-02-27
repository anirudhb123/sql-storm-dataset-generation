WITH RECURSIVE related_movies AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM
        movie_link ml
    WHERE
        ml.movie_id = (SELECT id FROM title WHERE title = 'The Matrix')

    UNION ALL

    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        rm.depth + 1
    FROM
        movie_link ml
    JOIN
        related_movies rm ON ml.movie_id = rm.linked_movie_id
),
movie_cast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
movie_info_with_keywords AS (
    SELECT
        t.title,
        t.production_year,
        m.info,
        k.keyword
    FROM
        title t
    LEFT JOIN
        movie_info m ON t.id = m.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT mc.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.actor_name) AS actor_count,
    COALESCE(AVG(m.production_year), 0) AS avg_production_year_of_linked_movies
FROM 
    title t
LEFT JOIN 
    movie_cast mc ON t.id = mc.movie_id
LEFT JOIN 
    related_movies rm ON t.id = rm.movie_id
LEFT JOIN 
    movie_info_with_keywords m ON t.id = m.id
LEFT JOIN 
    keyword k ON m.keyword = k.keyword
WHERE 
    t.production_year BETWEEN 1990 AND 2020
    AND (m.info IS NULL OR m.info NOT LIKE '%unknown%')
GROUP BY 
    t.title, t.production_year
ORDER BY 
    actor_count DESC, t.production_year ASC
LIMIT 10;
