WITH RECURSIVE MovieHiearchy AS (
    -- Step 1: Base case - get all movies
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    -- Step 2: Recursive case - get linked movies
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHiearchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(distinct ci.person_id) AS actor_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_exist,
    AVG(COALESCE(year(tki.info), 0)) AS avg_info_years,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM 
    MovieHiearchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info tki ON mh.movie_id = tki.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.production_year DESC, actor_count DESC;

### Explanation of the Query Components:

1. **Recursive CTE** (`MovieHiearchy`):
   - This part constructs a hierarchy of movies starting from those released in 2000 and recursively finds linked movies associated with the original movies.

2. **Left Joins**:
   - Joins are employed to pull together information from various tables such as `complete_cast`, `cast_info`, `movie_companies`, and `movie_info`, ensuring that we obtain comprehensive data even if some related records are missing.

3. **Aggregation**:
   - The query aggregates data to count distinct actors (`actor_count`), check for existing notes (`notes_exist`), and calculate the average of production years from movie info using `AVG` and `COALESCE` to handle NULLs.

4. **String Aggregation**:
   - `STRING_AGG` is used to compile a comma-separated list of company types associated with each movie.

5. **Conditional Logic**:
   - The use of `CASE` within the `SUM` allows us to dynamically count only the records that fulfill certain conditions (in this case, where notes exist).

6. **HAVING Clause**:
   - The query filters for movies that have at least one actor associated with it, ensuring the result set is relevant.

7. **Ordering**:
   - Lastly, the results are ordered first by production year in descending order and then by the actor count in descending order for an insightful presentation of the data.
