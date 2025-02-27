WITH RecursiveMovieTree AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting node: Movies produced from 2000 onwards
    
    UNION ALL
    
    SELECT 
        lm.id,
        lm.title,
        lm.production_year,
        lm.kind_id,
        level + 1,
        rmt.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title lm ON ml.linked_movie_id = lm.id
    JOIN 
        RecursiveMovieTree rmt ON ml.movie_id = rmt.movie_id
)

SELECT 
    rmt.title AS linked_movie_title,
    rmt.production_year AS linked_movie_year,
    a.name AS actor_name,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.subject_id) AS num_cast_members,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
    MAX(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS max_order
FROM 
    RecursiveMovieTree rmt
LEFT JOIN 
    complete_cast cc ON rmt.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id 
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id 
LEFT JOIN 
    movie_keyword mk ON rmt.movie_id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    rmt.level < 3  -- Limit the depth of the movie tree
GROUP BY 
    rmt.title, rmt.production_year, a.name
ORDER BY 
    rmt.production_year DESC, 
    num_cast_members DESC NULLS LAST;

This SQL query constructs a recursive common table expression (CTE) to create a movie link tree of movies produced in or after 2000. It then joins with various tables to gather details about the cast and associated keywords, accumulating counts and aggregating results. The output includes the titles of the linked movies, their production years, actor names, related keywords, the number of cast members, noted roles, and the maximum order of roles, while ensuring a meaningful order in the result set.
