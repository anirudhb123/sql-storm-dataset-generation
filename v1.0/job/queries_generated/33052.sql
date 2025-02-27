WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        (SELECT COUNT(DISTINCT cc.movie_id) 
         FROM complete_cast cc 
         WHERE cc.subject_id = ci.person_id) AS complete_cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT an.name) AS actor_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actor_names,
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS keyword_rank
    FROM 
        MovieInfo
    WHERE 
        production_year BETWEEN 2000 AND 2023
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_names,
    fm.keyword_count,
    ah.movie_count,
    ah.complete_cast_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorHierarchy ah ON ah.person_id = ANY(fm.actor_names)
WHERE 
    fm.keyword_count > 3
ORDER BY 
    fm.production_year DESC, 
    fm.keyword_count DESC
LIMIT 50;

### Explanation of the Query:

1. **CTE ActorHierarchy**: This recursive common table expression calculates the number of distinct movies each actor has been a part of, as well as their "complete cast" participation. Only actors with more than 5 movies are included.

2. **CTE MovieInfo**: It gathers movie titles, their production years, associated actor names, and counts the number of distinct keywords per movie. This involves outer joins, so movies can still be included even if they have no associated actors or keywords.

3. **CTE FilteredMovies**: This CTE filters movies produced between the years 2000 and 2023, ranks them based on the keyword count for each production year, allowing further analysis.

4. **Final Selection**: The main query selects the relevant information from `FilteredMovies`, joins with the `ActorHierarchy` on actor names, and includes filters and order by clauses to limit the rows returned and organize the output.

This query incorporates various SQL constructs such as window functions, outer joins, CTEs, and aggregated results, making it suitable for performance benchmarking and demonstrating SQL capabilities.
