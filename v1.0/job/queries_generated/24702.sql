WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
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
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MoviesOverview AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count,
        mk.keywords,
        COALESCE(NULLIF(rm.title_rank, 1), 2) AS title_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
),
FinalResults AS (
    SELECT 
        title,
        production_year,
        actor_count,
        keywords,
        CASE 
            WHEN actor_count IS NULL THEN 'No actors'
            WHEN title_rank <= 3 THEN 'Top Rank!'
            ELSE 'Regular Movie'
        END AS classification
    FROM 
        MoviesOverview
    WHERE 
        (actor_count > 5 OR keywords IS NOT NULL)
    ORDER BY 
        production_year DESC,
        title_rank ASC
)
SELECT 
    title, 
    production_year, 
    actor_count, 
    keywords, 
    classification
FROM 
    FinalResults
WHERE 
    NOT (keywords IS NULL AND actor_count < 5)
    OR (keywords IS NOT NULL AND actor_count IS NULL);

### Explanation:
1. **Common Table Expressions (CTEs)**: The query utilizes multiple CTEs such as `RankedMovies`, `ActorCount`, `MoviesWithKeywords`, and `MoviesOverview` to break down the tasks into manageable parts, calculating ranks, counts, and aggregating keywords.

2. **Row Number and Partitioning**: The `ROW_NUMBER()` function is used to rank movies based on their production year and title.

3. **Aggregation**: We count distinct actors per movie and aggregate keywords into a single string.

4. **Classification Logic**: A `CASE` statement is used to classify movies based on actor counts and ranking.

5. **NULL Logic**: The final selection includes complicated NULL logic by filtering out cases where both actor count and keywords are NULL while allowing for rows where one of them is present.

6. **Ordering**: The final results are ordered by production year and title rank, showcasing the structure and complexity.

7. **Set Operators and Boolean Logic**: The final query checks various conditions, manipulating NULL values and merging results strategically to reflect complex business logic, demonstrating sophisticated SQL usage.
