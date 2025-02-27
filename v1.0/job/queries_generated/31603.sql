WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(EXTRACT(YEAR FROM AGE(NOW(), t.production_year))) AS avg_movie_age,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(t.production_year) AS latest_movie_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title t ON mh.movie_id = t.id
WHERE 
    mh.level <= 2 AND 
    a.name IS NOT NULL
GROUP BY 
    a.name
ORDER BY 
    total_movies DESC
LIMIT 10;

This query begins with a recursive Common Table Expression (CTE) to generate a hierarchy of movies linked to companies based in the USA. It then selects the names of actors along with aggregated data about the movies they have appeared in, including total movies, average movie age, associated keywords, and the latest movie year. It applies joins, aggregates data, and filters, while also handling NULL values correctly.
