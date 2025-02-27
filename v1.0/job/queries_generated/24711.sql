WITH Recursive ActorRoles AS (
    SELECT ci.movie_id, ci.person_id, r.role, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    WHERE ci.nr_order IS NOT NULL
),
FilteredMovies AS (
    SELECT mt.id AS movie_id, mt.title, COUNT(DISTINCT ar.person_id) AS actor_count
    FROM aka_title mt
    LEFT JOIN ActorRoles ar ON mt.id = ar.movie_id
    WHERE mt.production_year BETWEEN 1990 AND 2020
    GROUP BY mt.id, mt.title
    HAVING COUNT(DISTINCT ar.person_id) > 5
),
MoviesWithCompany AS (
    SELECT fm.movie_id, fm.title, cm.name AS company_name, 
           COALESCE(SUM(CASE WHEN ct.kind LIKE '%Production%' THEN 1 END), 0) AS production_count
    FROM FilteredMovies fm
    LEFT JOIN movie_companies mc ON fm.movie_id = mc.movie_id
    LEFT JOIN company_name cm ON mc.company_id = cm.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY fm.movie_id, fm.title, cm.name
),
MovieKeywords AS (
    SELECT fm.movie_id, STRING_AGG(mk.keyword, ', ') AS keyword_list
    FROM FilteredMovies fm
    JOIN movie_keyword mk ON fm.movie_id = mk.movie_id
    GROUP BY fm.movie_id
),
FinalMovies AS (
    SELECT mw.movie_id, mw.title, mw.company_name, mw.production_count, mk.keyword_list
    FROM MoviesWithCompany mw
    LEFT JOIN MovieKeywords mk ON mw.movie_id = mk.movie_id
)
SELECT fm.*, 
       CASE 
           WHEN fm.production_count IS NULL THEN 'No Production Company'
           ELSE 'Production Company Exists'
       END AS production_status
FROM FinalMovies fm
WHERE fm.keyword_list IS NOT NULL
   OR fm.production_count > 2
ORDER BY fm.production_count DESC, fm.title ASC
LIMIT 100;

-- Additional nested query to retrieve the max actor roles for each movie.
SELECT movie_id, MAX(role_order) AS max_roles
FROM ActorRoles
GROUP BY movie_id
HAVING MAX(role_order) > 3;

This complex SQL query is designed to benchmark various SQL constructs including Common Table Expressions (CTEs), window functions, outer joins, grouping sets, and conditional logic. It filters movies based on the number of actors within a specified range and determines production companies while also aggregating associated keywords. Additionally, it demonstrates how to use NULL logic and nested queries effectively.
