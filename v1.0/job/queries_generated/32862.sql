WITH RECURSIVE hierarchical_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ll.movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        movie_link ll
    JOIN 
        aka_title m ON m.id = ll.linked_movie_id
    JOIN 
        hierarchical_movies hm ON hm.movie_id = ll.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT kv.info) FILTER (WHERE kv.info IS NOT NULL) AS keyword_information,
    CASE WHEN COUNT(DISTINCT k.keyword) > 5 THEN 'Many Keywords' ELSE 'Few Keywords' END AS keyword_status,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    hierarchical_movies m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mv ON m.movie_id = mv.movie_id
LEFT JOIN 
    movie_info_idx kv ON mv.info_type_id = kv.info_type_id AND mv.info = kv.info
WHERE 
    a.name IS NOT NULL
    AND m.production_year BETWEEN 1990 AND 2023
    AND (k.phonetic_code IS NULL OR k.phonetic_code != '')
GROUP BY 
    a.name, m.title, m.production_year
ORDER BY 
    keyword_count DESC, m.production_year ASC;

This SQL query does the following:
- It constructs a recursive CTE named `hierarchical_movies` to gather a list of movies and their relationships.
- It selects actor names from `aka_name`, joined with `cast_info` for movie associations.
- It retrieves associated keywords using left joins, counts them, and concatenates any relevant information from `movie_info` using an `ARRAY_AGG` function.
- It uses a conditional aggregate to determine the number of notes associated with each cast member's role in movies.
- It filters results based on production years and ensures that actor names are not null.
- Finally, it groups the results by actor name, movie title, and year, ordering by keyword count and production year.
