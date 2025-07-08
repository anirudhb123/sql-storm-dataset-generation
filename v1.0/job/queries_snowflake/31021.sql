
WITH RECURSIVE movie_series AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        1 AS level
    FROM
        title t
    WHERE
        t.episode_of_id IS NULL

    UNION ALL

    SELECT
        t2.id AS title_id,
        t2.title,
        t2.production_year,
        t2.season_nr,
        t2.episode_nr,
        t2.episode_of_id,
        m.level + 1 AS level
    FROM
        title t2
    INNER JOIN
        movie_series m ON t2.episode_of_id = m.title_id
), 

actor_performance AS (
    SELECT
        c.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
        AVG(m.production_year) AS average_production_year
    FROM
        cast_info c
    INNER JOIN
        aka_name a ON c.person_id = a.person_id
    INNER JOIN
        movie_series ms ON c.movie_id = ms.title_id
    LEFT JOIN 
        title m ON c.movie_id = m.id
    GROUP BY
        c.person_id, a.name
), 

keyword_summary AS (
    SELECT
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM
        movie_keyword m
    INNER JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
) 

SELECT
    ap.person_id,
    ap.name,
    ap.movie_count,
    ap.roles_count,
    ap.average_production_year,
    COALESCE(ks.keywords_list, 'No keywords') AS keywords_list,
    COALESCE(m.company_count, 0) AS company_count
FROM
    actor_performance ap
LEFT JOIN (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
) m ON m.movie_id = ap.movie_count
LEFT JOIN keyword_summary ks ON ks.movie_id = ap.movie_count
WHERE
    ap.average_production_year < (
        SELECT AVG(production_year) FROM title WHERE production_year IS NOT NULL
    )
ORDER BY
    ap.movie_count DESC,
    ap.roles_count DESC;
