WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ca.movie_id,
        1 AS level
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id 
    WHERE 
        a.name ILIKE '%Smith%'  -- filter actors by name
    UNION ALL
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        ca.movie_id,
        ah.level + 1
    FROM
        actor_hierarchy ah
    JOIN 
        cast_info ca ON ah.movie_id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        ah.level < 3  -- limit depth of recursion
),
movie_ranks AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.movie_id = ca.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
related_movies AS (
    SELECT 
        ml.movie_id AS current_movie_id,
        ml.linked_movie_id AS related_movie_id,
        lt.link AS relation_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        ml.linked_movie_id IS NOT NULL
),
keyword_filter AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword ILIKE '%action%' OR k.keyword ILIKE '%adventure%'
    GROUP BY 
        mk.movie_id
)
SELECT 
    ah.actor_name,
    mr.title,
    mr.production_year,
    mr.total_cast,
    rm.relation_type,
    kf.keywords
FROM 
    actor_hierarchy ah
JOIN 
    movie_ranks mr ON ah.movie_id = mr.movie_id 
LEFT JOIN 
    related_movies rm ON mr.movie_id = rm.current_movie_id 
LEFT JOIN 
    keyword_filter kf ON mr.movie_id = kf.movie_id 
WHERE 
    mr.rank <= 5  -- Top 5 movies per year based on cast count
ORDER BY 
    mr.production_year DESC, mr.total_cast DESC;
