WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
    MAX(r.role) AS main_role,
    AVG(ki.keyword_count) AS avg_keywords
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ca ON ca.movie_id = cc.movie_id
LEFT JOIN 
    role_type AS r ON ca.role_id = r.id
LEFT JOIN 
    (SELECT 
         mk.movie_id, COUNT(*) AS keyword_count
     FROM 
         movie_keyword AS mk
     GROUP BY 
         mk.movie_id) AS ki ON ki.movie_id = mh.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ca.person_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
ORDER BY 
    avg_keywords DESC, total_cast DESC, mh.production_year DESC;

This query constructs a recursive CTE to build a hierarchy of movies linked through the `movie_link` table. It gathers detailed information on each movie such as its title, production year, total cast count, names of actors, their main role, and average keywords associated with each movie. It uses a combination of outer joins, aggregates, and window functions, along with HAVING clauses to filter results based on the number of distinct cast members associated with each movie.
