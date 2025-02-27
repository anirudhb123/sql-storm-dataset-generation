WITH Recursive TitleCascade AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mtl.linked_movie_id
    FROM 
        title mt
    LEFT JOIN 
        movie_link mtl ON mt.id = mtl.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        tc.movie_id,
        t.title,
        t.production_year,
        mtl.linked_movie_id
    FROM 
        TitleCascade tc
    JOIN 
        movie_link mtl ON tc.linked_movie_id = mtl.movie_id
    JOIN 
        title t ON mtl.linked_movie_id = t.id
)
, RankedCasts AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT rc.actor_name, ', ') AS cast_names,
    COUNT(DISTINCT CASE WHEN rc.actor_name IS NOT NULL THEN 1 END) AS distinct_cast_count,
    COUNT(DISTINCT tc.linked_movie_id) AS related_movies_count,
    COALESCE((SELECT COUNT(*) 
              FROM movie_info mi 
              WHERE mi.movie_id = t.id 
              AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')), 0) AS genre_count
FROM 
    title t
LEFT JOIN 
    RankedCasts rc ON rc.movie_id = t.id
LEFT JOIN 
    TitleCascade tc ON tc.movie_id = t.id
GROUP BY 
    t.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT rc.actor_name) > 5
    AND COALESCE((SELECT COUNT(*) 
                  FROM movie_keyword mk 
                  WHERE mk.movie_id = t.id 
                  AND mk.keyword_id IN (SELECT id FROM keyword WHERE phonetic_code IS NULL)), 0) = 0
ORDER BY 
    t.production_year DESC, distinct_cast_count DESC;

### Explanation:
1. **Common Table Expressions (CTEs)**:
    - `TitleCascade`: A recursive CTE to find all movies linked to a particular title through movie links, capturing both direct and indirect links.
    - `RankedCasts`: Ranks actors in each movie based on their order (nr_order) in the cast.

2. **Main Query**:
    - Joins titles with their casts and linked movies.
    - Groups the results to aggregate the cast names and counts.
    
3. **Aggregate Functions**:
    - `STRING_AGG` is used to concatenate actor names for each movie.
    - `COUNT(DISTINCT...)` provides counts of distinct actors and related movies.

4. **Subqueries & NULL Logic**:
    - Subquery checks for the genre of each movie, with a `COALESCE` to handle NULL.
    - Uses predicates to filter results, including handling potential NULL values in the movie keyword.

5. **HAVING Clause**:
    - Filters only those movies with more than 5 distinct cast members and checks for those without NULL phonetic codes in keywords.

6. **ORDER BY**:
    - Orders the results primarily by production year and then by distinct cast count, facilitating performance benchmarking in analyzing complex joins and queries.

This SQL query intricately combines different SQL constructs to highlight performance benchmarking aspects effectively.
