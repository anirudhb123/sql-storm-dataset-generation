WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(t.title, 'No Series') AS series_title,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title t ON m.episode_of_id = t.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        t.title AS series_title,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    CONCAT(a.name, ' (', STRING_AGG(DISTINCT g.kind, ', '), ')') AS actor_name,
    mh.title AS movie_title,
    mh.series_title,
    mh.level AS series_level,
    COUNT(DISTINCT mw.keyword_id) AS total_keywords,
    AVG(COALESCE(ri.rating, 0)) AS avg_rating,
    MAX(CASE WHEN ci.nr_order = 1 THEN 'Main Role' ELSE 'Supporting Role' END) AS role_description
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    (SELECT movie_id, AVG(rating) as rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') GROUP BY movie_id) ri ON mh.movie_id = ri.movie_id
JOIN 
    role_type g ON ci.role_id = g.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, mh.title, mh.series_title, mh.level
HAVING 
    COUNT(DISTINCT mw.keyword_id) > 0
ORDER BY 
    series_level DESC, avg_rating DESC;
