WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    COUNT(DISTINCT c.id) AS cast_size,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_cast_size,
    AVG(p.rating) AS avg_rating,
    SUM(CASE WHEN i.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    COALESCE(k.keyword, 'No keywords') AS keyword_info
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    movie_info i ON i.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') GROUP BY movie_id) p ON p.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000 
GROUP BY 
    m.movie_id, m.title, m.production_year, k.keyword
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    m.production_year DESC, cast_size DESC;
