WITH movie_role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role AS role_type,
        COUNT(ci.id) AS role_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.id) DESC) AS role_rank
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
top_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        rpi.person_id AS director_id,
        ak.name AS director_name,
        SUM(mcs.role_count) AS total_roles,
        AVG(mcs.note_count) AS avg_notes_per_role
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id 
    LEFT JOIN company_name cn ON mc.company_id = cn.id AND cn.country_code = 'USA'
    LEFT JOIN complete_cast c ON mt.id = c.movie_id
    LEFT JOIN movie_role_summary mcs ON mt.id = mcs.movie_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director' LIMIT 1)
    LEFT JOIN person_info rpi ON mi.info = rpi.info AND rpi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director' LIMIT 1)
    LEFT JOIN aka_name ak ON rpi.person_id = ak.person_id
    WHERE mt.production_year IS NOT NULL
    GROUP BY mt.id, mt.title, mt.production_year, rpi.person_id, ak.name
    HAVING SUM(mcs.role_count) > 1 AND COUNT(DISTINCT mi.info_type_id) > 0
),
highest_role_counts AS (
    SELECT 
        movie_id,
        MAX(role_count) AS max_role_count
    FROM movie_role_summary
    GROUP BY movie_id
    HAVING MAX(role_count) >= 3
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.director_name,
    COALESCE(hrc.max_role_count, 0) AS most_common_role,
    tm.total_roles,
    tm.avg_notes_per_role 
FROM top_movies tm
LEFT JOIN highest_role_counts hrc ON tm.movie_id = hrc.movie_id
WHERE tm.production_year BETWEEN 2000 AND 2023
ORDER BY tm.avg_notes_per_role DESC, tm.total_roles DESC
LIMIT 10;
