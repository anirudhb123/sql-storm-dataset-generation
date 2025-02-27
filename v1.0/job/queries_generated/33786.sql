WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level 
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    coalesce(c.person_name, 'Unknown') AS main_actor,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = m.id) AS keyword_count,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = m.id) AS total_cast,
    RANK() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON c.movie_id = m.movie_id 
               AND c.nr_order = 1
LEFT JOIN 
    aka_name cn ON cn.person_id = c.person_id
WHERE 
    m.production_year BETWEEN 2010 AND 2020
    AND (m.movie_title ILIKE '%adventure%' OR m.movie_title ILIKE '%mystery%')
ORDER BY 
    m.production_year DESC, year_rank
LIMIT 50;

### Explanation:
1. **Common Table Expressions (CTEs)**: A recursive CTE (`MovieHierarchy`) is used to gather movies released after 2000 and their linked movies, facilitating a hierarchy of related movies.
2. **Subqueries**: Two correlated subqueries are included:
   - One to count distinct keywords associated with each movie.
   - Another to count the total number of cast members for each movie.
3. **Window Functions**: The `RANK()` window function ranks movies by production year.
4. **Outer Joins**: Left joins are used to ensure that if there’s no main actor found, it defaults to 'Unknown'.
5. **Complicated Predicates**: The query filters for a specific production year range (2010 to 2020) and movies that have specific keywords in their titles.
6. **NULL Logic**: The COALESCE function handles potential NULL values when there’s no main actor.
