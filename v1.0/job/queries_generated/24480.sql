WITH RecursiveRelatedTitles AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY[m.title] AS title_path,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        l.linked_movie_id AS movie_id,
        t.title AS movie_title,
        r.title_path || t.title,
        r.depth + 1
    FROM 
        movie_link AS l
    JOIN 
        title AS t ON l.linked_movie_id = t.id
    JOIN 
        RecursiveRelatedTitles AS r ON l.movie_id = r.movie_id
    WHERE 
        r.depth < 10 -- Limit the depth to avoid infinite recursion
),
MovieCast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
),
FullDetails AS (
    SELECT 
        rt.movie_id,
        rt.movie_title,
        ARRAY_AGG(DISTINCT m.actor_name ORDER BY m.actor_order) AS cast_names,
        COUNT(DISTINCT m.actor_name) AS actor_count,
        STRING_AGG(DISTINCT CASE WHEN at.year IS NULL THEN 'No Info' ELSE at.year::text END, ', ') AS production_years
    FROM 
        RecursiveRelatedTitles AS rt
    LEFT JOIN 
        MovieCast AS m ON rt.movie_id = m.movie_id
    LEFT JOIN 
        (SELECT movie_id, production_year AS year FROM aka_title) AS at ON rt.movie_id = at.movie_id
    GROUP BY 
        rt.movie_id, rt.movie_title
)
SELECT 
    fd.movie_id,
    fd.movie_title,
    fd.cast_names,
    fd.actor_count,
    COALESCE(NULLIF(fd.production_years, 'No Info'), 'Production Year Unknown') AS production_years
FROM 
    FullDetails AS fd
WHERE 
    fd.actor_count > 5
ORDER BY 
    fd.actor_count DESC, fd.movie_title DESC
LIMIT 10;

This query consists of several complex constructs, including:

1. **Common Table Expressions (CTEs)**: Recursive CTEs are used to find related titles linked via movie links, and a second CTE aggregates cast information by movie.

2. **Outer Joins**: Ensures that movies with no cast information still appear in the result set.

3. **Window Functions**: Utilized to rank actors by their order in each movie.

4. **ARRAY and STRING_AGG Functions**: Employed to compile lists of actor names and production years into array and comma-separated string formats.

5. **Complex Logic**: Uses `COALESCE` and `NULLIF` to handle different scenarios regarding missing production years.

6. **Complicated Predicates**: Filters for movies with more than five actors and incorporates corner cases handling for null and "no info" results.

This query benchmarks performance by combining aggregation, recursion, and filtering over potentially large datasets with various edge cases.
