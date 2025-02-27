WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.imdb_index,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        a.imdb_index,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    AVG(pi.info IS NOT NULL)::int AS has_biography,
    COUNT(DISTINCT ci.id) AS cast_count,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast_count,
    MAX(depth) AS max_depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id 
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Biography'
    )
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 5
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This CTE recursively builds a hierarchy of movies based on their links to other movies, collecting the `movie_id`, `title`, `production_year`, and `depth` of the hierarchy.

2. **Main Query**: The main body of the query performs the following operations:
   - Joins the `MovieHierarchy` with `movie_companies`, `company_name`, `complete_cast`, `cast_info`, and `person_info`.
   - Uses `STRING_AGG` to concatenate company names associated with each movie.
   - Calculates a score determining whether the movie has a biography using an average over a boolean expression.
   - Counts the number of cast and ordered cast members using `COUNT` and `SUM`.
   - Groups results on `movie_id`, `title`, and `production_year`.
   - Uses a `HAVING` clause to filter for movies with more than 5 cast members.
   
3. **Ordering**: Finally, it sorts the results by `production_year` in descending order and `cast_count`.

This query is designed for performance benchmarking by emphasizing the use of various SQL concepts such as CTEs, joins, aggregate functions, and filtering criteria.
