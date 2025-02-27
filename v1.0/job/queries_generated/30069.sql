WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
avg_cast_per_movie AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_title,
    COALESCE(aci.cast_count, 0) AS member_count,
    COALESCE(mci.companies, 'No Companies') AS companies,
    mh.level AS hierarchy_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    avg_cast_per_movie aci ON mh.movie_id = aci.movie_id
LEFT JOIN 
    movie_company_info mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.level < 3
ORDER BY 
    mh.level ASC, mh.movie_title;

### Explanation of the Query:

1. **Recursive CTE (`movie_hierarchy`)**: This common table expression builds a hierarchy of movies based on linked movies, starting from the original set of titles that have a production year. Each recursion level correlates to how deep in the hierarchy it is.

2. **Average Cast per Movie CTE (`avg_cast_per_movie`)**: This CTE calculates the number of unique cast members for each movie. It groups by `movie_id` and counts distinct `person_id`.

3. **Movie Company Information CTE (`movie_company_info`)**: This CTE aggregates all the companies associated with each movie into a single string, using `STRING_AGG`, providing a comprehensive list of production companies.

4. **Final SELECT**: The main query combines results from the hierarchy, cast counts, and company information using left joins. It also uses the COALESCE function to ensure that in case of NULL values (no cast or companies), a default message is returned.

5. **Filtering and Ordering**: It restricts the results to films that lie within the first two levels of the hierarchy and orders them by level and title.

This query reflects complex SQL constructs including recursive CTEs, aggregation, outer joins, and COALESCE for handling NULL values, providing a robust set of performance benchmarks.
