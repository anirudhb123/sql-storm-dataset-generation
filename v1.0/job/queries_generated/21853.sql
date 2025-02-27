WITH RecursiveRoles AS (
    -- Recursive CTE to get all roles for actors in a hierarchical manner, if applicable
    SELECT c.id AS cast_id, c.person_id, c.movie_id, c.nr_order,
           r.role AS role_name, 1 AS level
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE c.nr_order IS NOT NULL

    UNION ALL

    SELECT c.id AS cast_id, c.person_id, c.movie_id, c.nr_order,
           r.role AS role_name, rr.level + 1
    FROM cast_info c
    JOIN RecursiveRoles rr ON c.movie_id = rr.movie_id
    JOIN role_type r ON c.role_id = r.id
    WHERE c.nr_order IS NOT NULL AND rr.level < 5
),

-- CTE for aggregating movie info by production year
YearlyMovies AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT m.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM aka_title t
    JOIN movie_companies mc ON t.movie_id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN title m ON t.movie_id = m.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),

-- CTE for filtering movies based on keywords
FilteredMovies AS (
    SELECT m.id AS movie_id, m.title, k.keyword
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
    AND (k.keyword LIKE '%action%' OR k.keyword LIKE '%drama%')
),

-- CTE for overall cast information including roles and titles
CastDetails AS (
    SELECT 
        r.cast_id,
        r.person_id,
        r.role_name,
        t.title,
        r.nr_order,
        ROW_NUMBER() OVER (PARTITION BY r.movie_id ORDER BY r.nr_order) AS row_num
    FROM RecursiveRoles r
    JOIN FilteredMovies t ON r.movie_id = t.movie_id
)

SELECT 
    cd.person_id,
    COALESCE(NULLIF(EXTRACT(YEAR FROM CURRENT_DATE) - cm.production_year, 0), 'Unknown') AS years_active,
    COUNT(DISTINCT cd.movie_id) AS total_movies,
    STRING_AGG(DISTINCT cd.title, ', ') AS affected_movies,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT cd.movie_id) DESC) AS ranking
FROM CastDetails cd
LEFT JOIN YearlyMovies cm ON cd.title = ANY(STRING_TO_ARRAY(cm.titles, ', '))
GROUP BY cd.person_id, years_active
HAVING COUNT(DISTINCT cd.movie_id) > 1
ORDER BY total_movies DESC;
