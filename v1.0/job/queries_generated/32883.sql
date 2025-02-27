WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        title m

    UNION ALL

    -- Recursive case: Find linked movies
    SELECT 
        l.linked_movie_id AS movie_id, 
        t.title AS movie_title, 
        l.movie_id AS parent_movie_id,
        mh.level + 1 AS level
    FROM 
        movie_link l
    JOIN 
        title t ON l.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON l.movie_id = mh.movie_id
)
SELECT
    m.movie_title,
    COALESCE(t.production_year, 'Unknown') AS production_year,
    COUNT(DISTINCT c.person_id) AS total_cast_count,
    COUNT(DISTINCT km.keyword) AS total_keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS cast_names,
    RANK() OVER (PARTITION BY m.movie_id ORDER BY COUNT(DISTINCT km.keyword) DESC) AS keyword_rank,
    CASE
        WHEN t.production_year IS NULL THEN 'Unknown Year'
        WHEN t.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era
FROM 
    MovieHierarchy mh
JOIN 
    aka_title t ON t.id = mh.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
LEFT JOIN 
    keyword km ON km.id = mk.keyword_id
LEFT JOIN 
    aka_name cn ON cn.person_id = c.person_id
WHERE 
    mh.level <= 2
GROUP BY 
    m.movie_title, t.production_year
ORDER BY 
    total_keywords DESC, m.movie_title
LIMIT 50;
