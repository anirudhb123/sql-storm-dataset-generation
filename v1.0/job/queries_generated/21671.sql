WITH RankedTitles AS (
    SELECT
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS year_rank,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        a.id, a.title, a.production_year, a.kind_id
),
ActorCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
FilteredActors AS (
    SELECT 
        ci.person_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id 
    GROUP BY 
        ci.person_id
)
SELECT
    rt.title_id,
    rt.title,
    rt.production_year,
    ac.actor_count,
    rt.keywords,
    fa.actor_names
FROM
    RankedTitles rt
LEFT JOIN
    ActorCounts ac ON rt.title_id = ac.movie_id
LEFT JOIN
    FilteredActors fa ON fa.person_id IN (
        SELECT
            DISTINCT ci.person_id
        FROM 
            cast_info ci
        WHERE 
            ci.movie_id = rt.title_id
    )
WHERE
    rt.year_rank = 1
    AND rt.kind_id IS NOT NULL
    AND rt.keywords IS NOT NULL
ORDER BY
    rt.production_year DESC,
    rt.title;


This SQL query does the following:

1. **CTEs (Common Table Expressions)**: 
   - `RankedTitles`: Ranks titles by production year and gathers keywords associated with each title.
   - `ActorCounts`: Counts the number of distinct actors in each movie.
   - `FilteredActors`: Aggregates actor names grouped by their `person_id`.

2. **JOINs**: 
   - Combines information from `RankedTitles`, `ActorCounts`, and `FilteredActors`, using outer joins to ensure all titles are considered even if no actors or keywords are found.

3. **Window Functions**: 
   - Utilizes `ROW_NUMBER()` to rank titles by year and then alphabetically by title.

4. **STRING_AGG**: 
   - Collects keywords and actor names into single string entries for each title.

5. **Correlated Subqueries**: 
   - In the `WHERE` clause, a correlated subquery filters actors for each title.

6. **Filters**: 
   - Ensures that only the first-ranked title for each production year is included, and that both `kind_id` and `keywords` are not null.

7. **Ordering**: 
   - Results are ordered by production year (descending) and then by title to provide a clear view of the latest productions.
