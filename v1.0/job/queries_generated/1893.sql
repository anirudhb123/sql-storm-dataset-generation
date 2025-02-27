WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year
    FROM 
        RecursiveMovieTitles AS m
    WHERE 
        m.rn <= 5 
)
SELECT 
    p.name AS person_name,
    COALESCE(MAX(c.role_id), -1) AS role_id,
    COUNT(DISTINCT tm.movie_id) AS movies_count,
    STRING_AGG(DISTINCT tm.title, ', ' ORDER BY tm.title) AS titles,
    NULLIF(COUNT(DISTINCT c.person_id), 0) AS unique_cast_count
FROM 
    topMovies AS tm
LEFT JOIN 
    complete_cast AS cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name AS p ON c.person_id = p.person_id
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT tm.movie_id) > 2 
ORDER BY 
    unique_cast_count DESC
LIMIT 10;

SELECT 
    t1.title, 
    COUNT(DISTINCT t2.title) AS linked_movies_count 
FROM 
    aka_title AS t1 
JOIN 
    movie_link AS ml ON t1.movie_id = ml.movie_id 
JOIN 
    aka_title AS t2 ON ml.linked_movie_id = t2.movie_id 
WHERE 
    t1.production_year BETWEEN 1990 AND 1995 
GROUP BY 
    t1.title 
HAVING 
    COUNT(DISTINCT t2.title) > 0 
ORDER BY 
    linked_movies_count DESC 
LIMIT 5;
