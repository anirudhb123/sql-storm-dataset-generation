
WITH Recursive_Actors AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info c
    INNER JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.person_id, a.name
    HAVING
        COUNT(DISTINCT c.movie_id) > 1
),
Active_Movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(mk.keyword_list, '') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn  
    FROM
        aka_title t
    LEFT JOIN (
        SELECT
            mk.movie_id,
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
        FROM
            movie_keyword mk
        INNER JOIN
            keyword k ON mk.keyword_id = k.id
        GROUP BY
            mk.movie_id
    ) mk ON t.id = mk.movie_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
Title_Stats AS (
    SELECT
        a.movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM
        Active_Movies a
    LEFT JOIN
        cast_info ca ON a.movie_id = ca.movie_id
    LEFT JOIN
        info_type it ON it.id = ca.person_role_id
    LEFT JOIN
        movie_info ci ON a.movie_id = ci.movie_id
    GROUP BY
        a.movie_id, a.title, a.production_year
),
Final_Output AS (
    SELECT
        ts.movie_id,
        ts.title,
        ts.production_year,
        ts.cast_count,
        ts.has_note_ratio,
        COALESCE(ra.actor_name, 'Unknown') AS lead_actor
    FROM
        Title_Stats ts
    LEFT JOIN
        Recursive_Actors ra ON ts.cast_count > 0 AND ra.movie_count = (
            SELECT MAX(r.movie_count)
            FROM Recursive_Actors r
            WHERE r.person_id IN (
                SELECT DISTINCT ca.person_id
                FROM cast_info ca
                WHERE ca.movie_id = ts.movie_id
            )
        )
)

SELECT DISTINCT
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.cast_count,
    fo.has_note_ratio,
    fo.lead_actor
FROM
    Final_Output fo
WHERE
    fo.has_note_ratio > 0.5
ORDER BY
    fo.production_year DESC,
    fo.cast_count DESC
LIMIT 10 OFFSET 5;
