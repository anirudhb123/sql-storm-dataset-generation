WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Episode: ', m.title) AS title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(ci.id) AS cast_count,
    AVG(COALESCE(ri.age, 0)) AS average_age,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    case 
        when mh.production_year = 2023 then 'Latest'
        when mh.production_year < 2000 then 'Classic'
        else 'Modern'
    end as era
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    cast_info AS ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    (SELECT 
        p.person_id,
        EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM p.date_of_birth) AS age
    FROM person_info AS p
    WHERE p.info_type_id = (SELECT id FROM info_type WHERE info = 'date_of_birth')) AS ri ON ci.person_id = ri.person_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.production_year
ORDER BY 
    mh.production_year DESC,
    cast_count DESC;

### Explanation:
1. **Recursive CTE (Common Table Expression)**: 
   - The `MovieHierarchy` CTE retrieves top-level movies and their episodes. It differentiates between movies and episodes and maintains a lineage structure.

2. **Main Selection**:
   - The main query retrieves movie details, including `movie_id`, `title`, `production_year`, `cast_count`, `average_age`, and a list of actor names.
   - For calculating age, a subquery derives age from a date of birth found in `person_info`.

3. **Joins**:
   - It utilizes left outer joins to account for movies that might not have a cast or age information.

4. **Aggregate and Window Functions**:
   - `COUNT` to get the total number of cast members per movie.
   - `AVG` to calculate the average age of cast members, using `COALESCE` to handle `NULL` values.

5. **String Aggregation**:
   - `STRING_AGG` is used to concatenate the names of the actors into a single string.

6. **CASE Statement**:
   - A CASE expression is applied to determine the era of the movie based on its production year.

7. **Ordering**:
   - The results are ordered by production year (latest first) and by cast count, providing a performance benchmark spin by examining movie data in a multi-dimensional aspect.
