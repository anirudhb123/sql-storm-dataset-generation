WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS title, 
        t.production_year AS year,
        ARRAY[t.title] AS title_path
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        m.movie_id, 
        t.title, 
        t.production_year,
        title_path || t.title
    FROM 
        movie_link ml
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    JOIN 
        RecursiveMovieTitles m ON ml.movie_id = m.movie_id
)

SELECT 
    rmt.movie_id,
    rmt.title,
    rmt.year,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ARRAY_LENGTH(rmt.title_path, 1) AS path_length
FROM 
    RecursiveMovieTitles rmt
JOIN 
    cast_info ci ON rmt.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON rmt.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON rmt.movie_id = mk.movie_id
GROUP BY 
    rmt.movie_id, rmt.title, rmt.year
HAVING 
    COUNT(DISTINCT a.name) > 1 -- Filter for movies with multiple actors
ORDER BY 
    rmt.year DESC, 
    path_length DESC; 
