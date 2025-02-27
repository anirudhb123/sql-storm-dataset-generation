WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS actor_count
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    JOIN role_type r ON c.role_id = r.id
    WHERE a.production_year IS NOT NULL
),
AggregatedInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles_list
    FROM RankedMovies rm
    GROUP BY rm.title, rm.production_year, rm.actor_count
),
FilteredMovies AS (
    SELECT 
        ai.title,
        CASE
            WHEN ai.actor_count = 0 THEN 'No actors available'
            WHEN ai.actor_count > 10 THEN 'Many actors'
            ELSE 'Few actors'
        END AS actor_status,
        ai.roles_list
    FROM AggregatedInfo ai
    WHERE ai.actor_count > 5
)
SELECT 
    fm.title, 
    fm.actor_status,
    fm.roles_list,
    COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)), 0) AS keyword_count,
    CASE 
        WHEN fm.title LIKE '%(remake)%' THEN 'Remake'
        ELSE 'Original'
    END AS movie_type
FROM FilteredMovies fm
LEFT JOIN movie_info mi ON fm.title ILIKE '%' || mi.info || '%' -- Possible substrings
LEFT JOIN (SELECT DISTINCT movie_id FROM movie_companies WHERE company_type_id IN (SELECT id FROM company_type WHERE kind ILIKE '%Production%')) mc
    ON fm.title ILIKE '%' || (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1) || '%'
WHERE fm.roles_list IS NOT NULL
ORDER BY fm.actor_status DESC, fm.title;
