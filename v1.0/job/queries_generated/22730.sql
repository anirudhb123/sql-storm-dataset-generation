WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.person_id,
        tc.title_id,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year) AS movie_rank
    FROM cast_info c
    JOIN title t ON c.movie_id = t.id
    INNER JOIN RankedTitles tc ON t.id = tc.title_id
    WHERE c.note IS NULL OR c.note NOT LIKE '%Cameo%'
)
SELECT 
    a.person_id,
    a.name,
    COUNT(DISTINCT am.title_id) AS movie_count,
    AVG(am.movie_rank) AS avg_movie_rank,
    MAX(am.movie_rank) AS max_movie_rank,
    STRING_AGG(DISTINCT am.title, ', ') AS titles
FROM aka_name a
LEFT JOIN ActorMovies am ON a.person_id = am.person_id
LEFT JOIN (
    SELECT 
        ca.person_id,
        COUNT(ca.movie_id) AS cameo_count
    FROM cast_info ca
    WHERE ca.note LIKE '%Cameo%'
    GROUP BY ca.person_id
) cameo ON a.person_id = cameo.person_id
WHERE a.name IS NOT NULL
GROUP BY a.person_id, a.name
HAVING COUNT(DISTINCT am.title_id) > 0 OR COALESCE(cameo.cameo_count, 0) > 2
ORDER BY movie_count DESC, a.person_id
LIMIT 50;

### Explanation of Query Constructs:
1. **CTEs (Common Table Expressions)**: 
   - `RankedTitles` ranks titles by their production year for easier querying.
   - `ActorMovies` filters out actors with "Cameo" roles and ranks movies for each person.

2. **Joins**: 
   - **LEFT JOIN** to include all actors even if they have no associated movies from `ActorMovies`.
   - **INNER JOIN** and a secondary `LEFT JOIN` to connect actor names with cameo counts.

3. **Window Functions**: 
   - `RANK()` and `ROW_NUMBER()` are used for ranking titles based on the production year and movies per actor.

4. **Aggregation**: Using `COUNT`, `AVG`, and `STRING_AGG` to get statistics per actor, including their titles and average ranking, handling potential NULLs gracefully.

5. **HAVING Clause**: Ensures the result includes actors who either starred in more than zero movies or have a cameo count greater than 2.

6. **String Expressions**: The use of a string aggregation function to list all titles for the actors.

7. **NULL Logic**: The query explicitly handles NULL values for actor names and cameo roles.

8. **Complicated Predicates/Conditions**: The query includes complex conditions in the `WHERE` clause to filter actors based on their roles and conditions related to their names. 

This query is intended for performance benchmarking, showcasing various constructs while potentially hitting edge cases in the data schema defined.
