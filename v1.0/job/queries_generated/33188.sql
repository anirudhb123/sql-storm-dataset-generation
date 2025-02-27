WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(*) OVER (PARTITION BY ak.person_id, at.production_year) AS movie_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS info_count
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
WHERE 
    at.production_year BETWEEN 2010 AND 2020
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year, ct.kind
HAVING 
    movie_count > 1
ORDER BY 
    at.production_year DESC, movie_count DESC;

### Explanation:
- **CTE**: A recursive common table expression (`movie_hierarchy`) is used to build a hierarchy of movies based on their links to one another, starting from the most recent movies.
- **Joins**: Using multiple joins to get data from related tables like `aka_name`, `aka_title`, `cast_info`, `movie_keyword`, and `company_type`.
- **Window function**: `COUNT(*) OVER (PARTITION BY ...)` is used to calculate the count of movies for each actor per year.
- **String Aggregation**: `STRING_AGG` function collects keywords associated with each movie.
- **Conditional Aggregation**: `SUM(CASE ...)` counts specific types of info related to each movie.
- **COALESCE**: Used to handle cases where the company type may be NULL, replacing it with 'Unknown'.
- **Filtering**: To focus on movies produced between 2010 and 2020 and excluding NULL names.
- **Grouping and Ordering**: Results are grouped by actor name and movie title while ordering by the production year and movie count to prioritize recent works and prolific actors.
