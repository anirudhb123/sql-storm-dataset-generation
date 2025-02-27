WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(SUM(mci.note IS NOT NULL)::int, 0) AS total_companies,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keyword_list,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ah.name) AS actor_rank
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ah ON ci.person_id = ah.person_id
LEFT JOIN 
    movie_companies mci ON mci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.level <= 2
    AND (mh.production_year IS NULL OR mh.production_year >= 2000)
GROUP BY 
    ah.name, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC,
    total_keywords DESC,
    actor_rank;

### Explanation:
1. **CTE MovieHierarchy**: A recursive Common Table Expression is defined to create a hierarchy of movies, enabling us to look at movies linked to others.

2. **Main Query**:
   - **Selected Fields**: It selects the actor's name, movie title, production year, total companies involved in the production, a count of distinct keywords, and an aggregated list of keywords for each movie.
   - **Joins**: It joins the `MovieHierarchy` with `cast_info` and `aka_name` to get the actor details, and it uses left joins on `movie_companies` and `movie_keyword` tables.
   - **COALESCE & SUM**: It counts the number of companies associated with each movie, returning 0 if there are none.
   - **Window Function**: `ROW_NUMBER()` is employed to rank actors for each movie, ordered by their names.
   - **WHERE Clause**: It restricts the depth of movie links to 2 and considers movies produced from the year 2000 onwards.

3. **Ordering**: The results are ordered firstly by the production year in descending order, then by the count of keywords, and finally by actor rank within each movie.

This elaborate query touches on many advanced SQL topics and should serve as a solid benchmark for performance testing.
