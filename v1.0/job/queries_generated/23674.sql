WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        ka.person_id,
        kt.title,
        kt.production_year,
        kt.id AS title_id,
        COUNT(*) OVER (PARTITION BY ka.person_id) AS total_roles
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        aka_title kt ON c.movie_id = kt.movie_id
    WHERE 
        kt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
NullRatedTitles AS (
    SELECT 
        at.*,
        COALESCE(NULLIF(at.title, ''), 'Untitled') AS title_filled
    FROM 
        ActorTitles at
    WHERE 
        at.production_year IS NOT NULL
)
SELECT 
    n.name,
    rt.title AS ranked_title,
    rt.production_year,
    rank() OVER (PARTITION BY rt.production_year ORDER BY rt.title ASC) AS title_rank,
    COUNT(DISTINCT at.person_id) AS actor_count,
    AVG(coalesce(at.total_roles, 0)) AS avg_roles_per_actor,
    SUM(CASE WHEN nk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_present_count
FROM 
    NullRatedTitles rt
LEFT JOIN 
    name n ON n.id = rt.title_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = rt.title_id
LEFT JOIN 
    keyword nk ON nk.id = mk.keyword_id
GROUP BY 
    n.name, rt.title, rt.production_year 
HAVING 
    COUNT(DISTINCT at.person_id) > 1 AND rt.production_year > 2000
ORDER BY 
    rt.production_year DESC, title_rank ASC;

### Explanation:
1. **CTEs**: We start by creating multiple Common Table Expressions (CTEs) to structure our query's logic:
   - `RankedTitles`: Ranks titles based on their production year and title.
   - `ActorTitles`: Collects roles by actors for relevant movie titles.
   - `NullRatedTitles`: Handles potential NULL values in titles, replacing them with 'Untitled'.

2. **Joins**: We use `LEFT JOIN` to connect `NullRatedTitles` with `name`, `movie_keyword`, and `keyword`. This allows us to gather additional information for titles.

3. **Window Functions**: We use `ROW_NUMBER()` in `RankedTitles`, `COUNT()` in `ActorTitles`, and `avg_roles_per_actor` to calculate averages across groups.

4. **Complex Conditions**: The query includes intricate conditions like checking for NULLs and performing aggregations with `HAVING` to filter titles.

5. **String Manipulation**: The query utilizes `COALESCE` and `NULLIF` to ensure that we can handle empty titles gracefully.

6. **Aggregation**: Finally, we perform other aggregations like counting distinct actors and averaging roles while grouping the data by title attributes.

This complex SQL query incorporates many advanced SQL features and is structured to provide insights into film titles while accommodating potential edge cases and NULL logic.
