WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM aka_title t
),
ActorRoles AS (
    SELECT 
        a.name,
        ci.movie_id,
        r.role,
        COUNT(ci.id) AS role_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.name, ci.movie_id, r.role
),
TopActors AS (
    SELECT 
        name,
        movie_id,
        role,
        role_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY role_count DESC) AS role_rank
    FROM ActorRoles
),
FilteredActors AS (
    SELECT 
        ta.name,
        tm.title,
        tm.production_year,
        COALESCE((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ta.movie_id AND mi.info_type_id = 1), 0) AS info_count
    FROM TopActors ta
    JOIN RankedMovies tm ON ta.movie_id = tm.movie_id
    WHERE ta.role_rank <= 3 -- Top 3 roles
),
FinalActors AS (
    SELECT 
        fa.*,
        CASE 
            WHEN fa.info_count > 0 THEN 'Active' 
            ELSE 'Inactive' 
        END AS actor_status,
        CASE 
            WHEN fa.production_year < 2000 THEN 'Classic'
            WHEN fa.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Contemporary'
        END AS era
    FROM FilteredActors fa
)
SELECT 
    fa.name,
    fa.title,
    fa.production_year,
    fa.actor_status,
    fa.era
FROM FinalActors fa
WHERE fa.actor_status = 'Active' 
AND fa.production_year = (SELECT MAX(production_year) FROM FinalActors)
ORDER BY fa.name, fa.title;

This elaborate SQL query achieves several objectives while incorporating various SQL constructs:

1. **Common Table Expressions (CTEs)**: It employs multiple CTEs to break down the query into manageable segments, such as ranked movies, actor roles aggregation, and filtering based on role ranks.

2. **Window Functions**: It uses window functions to rank titles per production year and to determine the most common roles played by actors.

3. **Correlated Subqueries**: The query includes a subquery to count associated movie information where the count might be NULL.

4. **NULL Logic**: The `COALESCE` function ensures that when there is no information found, it defaults to zero.

5. **Complicated Predicates**: The `CASE` statements categorize actors based on their activity status and the era of production.

6. **String Expressions**: The selection includes text fields to display names and titles directly.

This query allows for detailed insights into actors, their roles, and the movies they participated in, filtering for active actors in the latest production year and classifying them categorically.
