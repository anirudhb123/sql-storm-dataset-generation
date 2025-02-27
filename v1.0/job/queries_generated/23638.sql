WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 3
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        p.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
)
SELECT 
    tt.title,
    tt.production_year,
    COUNT(DISTINCT ciw.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ciw.actor_name, ', ') AS actor_list,
    MAX(CASE WHEN ciw.role_name LIKE '%lead%' THEN ciw.actor_name END) AS lead_actor,
    SUM(CASE WHEN ciw.role_name IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
FROM 
    TopRankedTitles tt
LEFT JOIN 
    CastInfoWithRoles ciw ON tt.title_id = ciw.movie_id
GROUP BY 
    tt.title, 
    tt.production_year
HAVING 
    COUNT(ciw.actor_name) > 1
ORDER BY 
    tt.production_year DESC,
    tt.title ASC;

This SQL query involves several interesting constructs:

1. **CTEs** (Common Table Expressions): Used to structure the query.
   - `RankedTitles`: Ranks titles by production year and title.
   - `TopRankedTitles`: Filters the top 3 titles per production year.
   - `CastInfoWithRoles`: Joins the cast info with role types and aka names.

2. **Window Functions**: Row number is assigned to titles based on year which helps in filtering.

3. **LEFT JOIN**: Included to ensure that all top-ranked titles are shown even if they have no cast available.

4. **Aggregation**: `COUNT`, `STRING_AGG`, and `SUM` to get dynamic data about actors associated with the titles.

5. **MAX with CASE**: To find the lead actor for each title.

6. **HAVING Clause**: Ensures that only titles with more than one actor are considered for the final result.

7. **Bizarre SQL Semantics**: The use of `STRING_AGG` could potentially create unusual outputs depending on the data, especially in cases with NULL or empty names.

This approach efficiently showcases the desired complexity while staying within the schema provided.
