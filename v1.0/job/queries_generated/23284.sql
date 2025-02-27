WITH Recursive_CTE AS (
    SELECT
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_sequence
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%feature%')
),
Director_Roles AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM
        cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE
        r.role = 'director'
    GROUP BY
        c.movie_id
),
Popular_Movies AS (
    SELECT
        m.movie_id,
        COUNT(k.keyword) AS keyword_count
    FROM
        movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
    HAVING COUNT(k.keyword) > 10
)
SELECT
    r.actor_name,
    r.movie_title,
    r.production_year,
    r.actor_sequence,
    COALESCE(d.director_count, 0) AS director_count,
    COALESCE(pm.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN r.actor_sequence = 1 THEN 'Lead Actor'
        WHEN r.actor_sequence <= 3 THEN 'Supporting Actor'
        ELSE 'Background Actor'
    END AS role_type,
    CASE
        WHEN d.director_count IS NULL THEN 'No Directors'
        WHEN d.director_count > 2 THEN 'Multiple Directors'
        ELSE 'Single Director'
    END AS director_status,
    CONVERT_VARCHAR(r.actor_name) + ' - ' + CONVERT_VARCHAR(r.movie_title) AS actor_movie
FROM
    Recursive_CTE r
LEFT JOIN
    Director_Roles d ON r.movie_id = d.movie_id
LEFT JOIN
    Popular_Movies pm ON r.movie_id = pm.movie_id
WHERE
    (r.production_year >= 2000 AND r.production_year <= 2022)
    AND (r.actor_name IS NOT NULL AND r.movie_title IS NOT NULL)
ORDER BY
    r.production_year DESC,
    r.actor_sequence
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

