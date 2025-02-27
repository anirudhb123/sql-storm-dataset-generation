WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_in_year
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),

ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(t.production_year) AS average_production_year
    FROM 
        cast_info ci
    JOIN 
        RankedMovies t ON ci.movie_id = t.movie_id
    GROUP BY 
        ci.person_id
),

ActorsWithMultipleMovies AS (
    SELECT 
        ak.name,
        cm.kind AS company_kind,
        amc.movies_count,
        amc.average_production_year
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts amc ON ak.person_id = amc.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ak.person_id)    
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    WHERE 
        amc.movies_count > 1
)

SELECT 
    a.name AS actor_name,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
    COUNT(DISTINCT m.id) AS movie_count,
    MAX(mt.info) AS movie_info,
    SUM(CASE WHEN mt.info_type_id = 1 THEN 1 ELSE 0 END) AS specific_info_count
FROM 
    ActorsWithMultipleMovies a
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
LEFT JOIN 
    movie_info mt ON mt.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
LEFT JOIN 
    aka_title m ON m.id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
GROUP BY 
    a.name, mk.keyword
HAVING 
    COUNT(DISTINCT m.id) > 2 OR MAX(mt.info) IS NOT NULL
ORDER BY 
    a.name, movie_count DESC;

This SQL query demonstrates a variety of complex SQL constructs:

- **Common Table Expressions (CTEs)**: It uses several CTEs, such as `RankedMovies`, `ActorMovieCounts`, and `ActorsWithMultipleMovies`, to organize the logic and gather insights step by step.
- **Window Functions**: The `ROW_NUMBER()` function assigns a rank to movies produced in the same year.
- **Outer Joins**: Left joins are used to include information from optional tables, allowing NULL results where no matches occur.
- **Correlated Subqueries**: Multiple subqueries in the `IN` clause demonstrate correlated relationships across multiple tables.
- **Aggregation Functions**: It includes `COUNT`, `AVG`, and `SUM` to summarize data.
- **CASE Expressions**: These expressions help count occurrences based on specific conditions.
- **NULL Handling**: The use of `COALESCE` to manage NULL situations and provide fallback values.
- **HAVING Clause**: It filters results based on aggregated conditions. 

This query is well-suited for performance benchmarking, given its complexity and varied constructs.
