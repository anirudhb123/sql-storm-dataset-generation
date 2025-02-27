WITH RecursiveTitleCTE AS (
    -- Recursive CTE to get all movie titles and their associated data
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COALESCE(k.keyword, 'No Keyword') AS keyword_col
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastCountPerMovie AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        rt.*,
        COALESCE(cc.actor_count, 0) AS total_actors
    FROM 
        RecursiveTitleCTE rt
    LEFT JOIN 
        CastCountPerMovie cc ON rt.title_id = cc.movie_id
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN total_actors > 5 THEN 'Popular'
            ELSE 'Less Popular' 
        END AS popularity
    FROM 
        MoviesWithKeywords
    WHERE 
        (production_year IS NOT NULL AND production_year BETWEEN 2000 AND 2020)
        OR (keyword_col = 'Horror' AND production_year < 2000)
)

SELECT 
    f.title,
    f.production_year,
    f.keyword_col,
    f.total_actors,
    f.popularity,
    STRING_AGG(DISTINCT c.name, ', ') AS actor_names,
    COUNT(DISTINCT CASE WHEN f.total_actors IS NULL THEN NULL END) AS null_actor_count
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info ci ON f.title_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
WHERE 
    (f.popularity = 'Popular' OR f.keyword_col ILIKE '%Drama%')
GROUP BY 
    f.title_id, f.title, f.production_year, f.keyword_col, f.total_actors, f.popularity
ORDER BY 
    f.production_year DESC, f.title_rank
LIMIT 50;

This SQL query incorporates a range of complex constructs such as:
- Recursive Common Table Expressions (CTEs) to retrieve movie titles and their details.
- A CTE to count actors per movie with a left join, handling cases where no actors are associated.
- A filtering CTE to classify movies based on their production year and the presence of particular keywords.
- A main query that aggregates actor names and counts NULLs using conditional counting. 
- Finally, string aggregation is applied to gather actor names from the results while leveraging common SQL constructs like outer joins and complicated predicates.
