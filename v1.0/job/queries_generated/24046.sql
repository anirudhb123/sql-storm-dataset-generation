WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT m.company_id) OVER (PARTITION BY a.id) AS company_count,
        MAX(c.kind) AS highest_kind
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    LEFT JOIN 
        company_type c ON m.company_type_id = c.id
    WHERE 
        a.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ' ORDER BY ak.name) AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        r.*,
        a.actor_count,
        a.actors
    FROM 
        RankedMovies r
    JOIN 
        ActorMovies a ON r.movie_id = a.movie_id
    WHERE 
        a.actor_count > 5 
        AND r.company_count >= 2
        AND r.highest_kind IS NOT NULL
        AND r.production_year BETWEEN 1990 AND 2020
),
HighRankedMovies AS (
    SELECT 
        *,
        CASE 
            WHEN title_rank IN (1, 2) THEN 'Top Title'
            WHEN title_rank IN (3, 4) THEN 'Middle Title'
            ELSE 'Other Title'
        END AS title_category
    FROM 
        FilteredMovies
)
SELECT 
    h.movie_id,
    h.title, 
    h.production_year,
    h.actor_count,
    h.actors,
    h.title_category,
    CASE 
        WHEN h.production_year % 10 = 0 THEN 'Decade Milestone'
        ELSE 'Regular Year'
    END AS production_year_type,
    COALESCE(NULLIF(h.actors, ''), 'Unknown Actors') AS actor_display
FROM 
    HighRankedMovies h
WHERE 
    h.production_year = 
        (SELECT MAX(production_year) 
         FROM HighRankedMovies 
         WHERE title_category = 'Top Title')
ORDER BY 
    h.production_year DESC, 
    h.title;

### Query Breakdown:
1. **CTE Definitions**:
   - `RankedMovies`: Ranks movies by title within each production year and counts distinct companies associated with each movie.
   - `ActorMovies`: Counts distinct actors in each movie and aggregates their names into a string.
   - `FilteredMovies`: Joins the previous two CTEs to filter movies with more than 5 actors and at least 2 associated companies, while also ensuring the highest company kind is available.
   - `HighRankedMovies`: Assigns categories based on the title rank.

2. **Main Select Statement**: Extracts and formats the final output. It classifies the production year and handles NULL values for actor names robustly.

3. **Use of SQL Constructs**: Includes window functions (`ROW_NUMBER`, `COUNT`), `STRING_AGG`, correlated subqueries, complex predicates, and NULL logic with `COALESCE` and `NULLIF`, disallowing empty actor listings.

4. **Bizarre Semantics**: Implies movie significance based on the decade of the production year and characterizes films into 'Top Title' or 'Middle Title' based on rank, thus creating multiple layers of categorization. The handling of actor names with complex NULL logic is a corner case for ensuring meaningful output regardless of database state.
