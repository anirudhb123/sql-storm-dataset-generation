WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title AS t
    WHERE 
        t.production_year > 2000  -- Filter for movies produced after 2000

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS t ON ml.linked_movie_id = t.id
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    mh.production_year,
    COALESCE(kw.keyword, 'No Keyword') AS movie_keyword,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank,
    COUNT(ci.person_id) AS actor_count
FROM
    MovieHierarchy AS mh
JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
WHERE 
    mh.level <= 2 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, mh.production_year, kw.keyword
HAVING 
    COUNT(ci.person_id) > 1
ORDER BY 
    mh.production_year DESC, actor_rank;

This SQL query performs the following operations:

1. **Recursive CTE (`MovieHierarchy`)**: Constructs a hierarchy of movies produced after 2000, pulling linked movies through the `movie_link` table, while categorizing the levels.

2. **Main Query**:
   - Joins multiple tables (`complete_cast`, `cast_info`, `aka_name`, `movie_keyword`, and `keyword`) to obtain data about actors, the movies they participated in, and associated keywords.
   - Uses conditional logic by utilizing `COALESCE` to handle the possibility of missing keywords.
   - Applies the `RANK()` window function to create a ranking of actors based on their appearances in movies for a given year.
   - Filters out actors without a name and only includes entries where an actor has appeared in more than one movie.
   - Groups the results by actor name, movie title, production year, and keyword.
   - Orders the results by production year (descending) and actor rank to provide a structured view of actors’ contributions across years.

This query can be utilized for benchmarking performance related to complex joins, subqueries, and aggregate calculations.
