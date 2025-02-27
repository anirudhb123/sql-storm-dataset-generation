WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        rk.role AS role,
        COALESCE(CAST(mk.keyword AS text), 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_order,
        COUNT(*) OVER (PARTITION BY mt.id) AS actor_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type rk ON ci.role_id = rk.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
        AND (mt.kind_id IN (1, 2, 3) OR mt.title LIKE '%Action%')
),
KeywordAggr AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
),
ActorRanked AS (
    SELECT 
        *,
        CASE 
            WHEN actor_order = 1 THEN 'Lead Actor'
            WHEN actor_order <= 3 THEN 'Supporting Actor'
            ELSE 'Minor Role'
        END AS actor_rank
    FROM 
        MovieDetails
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ka.keywords, 'No Keywords Associated') AS keywords,
    STRING_AGG(DISTINCT ar.actor_name || ' (' || ar.actor_rank || ')', ', ') AS actors_list,
    COUNT(DISTINCT ar.actor_name) AS distinct_actor_count,
    CASE 
        WHEN COUNT(DISTINCT ar.actor_name) > 5 THEN 'Ensemble Cast'
        WHEN COUNT(DISTINCT ar.actor_name) < 1 THEN 'No cast information'
        ELSE 'Standard Cast'
    END AS cast_size_category
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordAggr ka ON md.movie_id = ka.movie_id
LEFT JOIN 
    ActorRanked ar ON md.movie_id = ar.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, ka.keywords
HAVING 
    COUNT(DISTINCT ar.actor_name) > 0
ORDER BY 
    md.production_year DESC, md.title
LIMIT 50;

### Explanation:

1. **CTEs**: 
   - `MovieDetails`: This pulls together essential movie and actor information, including keywords, and ranks actors within each movie.
   - `KeywordAggr`: This aggregates keywords associated with each movie into a string.
   - `ActorRanked`: This classifies actors based on their ranking in the cast.

2. **Joins**:
   - Multiple `LEFT JOIN`s are used to connect movies to cast information, actors, roles, and keywords. This ensures that we can fetch all relevant data even for movies with no cast or keywords.

3. **Window Functions**:
   - The `ROW_NUMBER()` function aids in numbering actors for each movie, enabling us to mark lead actors versus supporting actors.

4. **String Aggregation**:
   - `STRING_AGG` combines keywords and creates a list of actors with their roles.

5. **Predicates and Conditional Logic**:
   - Complex predicates in the `WHERE` clause filter movies based on production years and kind IDs.
   - The `CASE` statement in the main select classifies actors and determines the cast size category.

6. **NULL Logic**:
   - `COALESCE` is used throughout to ensure that NULL values don't lead to undesirable outcomes, providing default texts where necessary.

7. **Bizarre Behavior**:
   - The use of `HAVING` to enforce that only movies with at least one actor appear in the final result list can lead to some intricate logical scenarios, particularly for movies that may have been produced but not feature any cast listed.
  
This query is designed to cover a wide variety of SQL features, combining complexity with utility for performance benchmarking while remaining within the prescribed database schema.
