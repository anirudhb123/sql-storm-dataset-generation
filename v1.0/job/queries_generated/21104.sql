WITH ranked_titles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY a.id) AS total_movies
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
),
movie_company_info AS (
    SELECT
        m.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mi.info, 'No info available') AS movie_info
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN
        movie_info mi ON mc.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Release Date')
),
actor_movie_stats AS (
    SELECT
        rt.actor_name,
        rt.movie_title,
        rt.production_year,
        mci.company_name,
        mci.company_type,
        rt.total_movies,
        CASE 
            WHEN rt.rn = 1 THEN 'Latest'
            WHEN rt.total_movies > 5 THEN 'Frequent Actor'
            ELSE 'Occasional Actor'
        END AS actor_category
    FROM
        ranked_titles rt
    LEFT JOIN
        movie_company_info mci ON rt.movie_title = mci.movie_name
)
SELECT
    am.actor_name,
    am.movie_title,
    am.production_year,
    am.company_name,
    am.company_type,
    am.actor_category,
    CASE
        WHEN am.total_movies > 3 THEN 'Highly Active'
        WHEN am.total_movies BETWEEN 1 AND 3 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS activity_status
FROM
    actor_movie_stats am
WHERE
    am.actor_category <> 'Occasional Actor'
    AND am.company_name IS NOT NULL
ORDER BY
    am.production_year DESC,
    am.actor_name ASC;
