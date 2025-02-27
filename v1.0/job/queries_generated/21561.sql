WITH movie_years AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
),
actor_stats AS (
    SELECT
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        AVG(mt.production_year) AS avg_production_year,
        STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        aka_title mt ON ci.movie_id = mt.movie_id
    WHERE
        ak.name IS NOT NULL
    GROUP BY
        ak.person_id, ak.name
),
famous_actors AS (
    SELECT
        ps.person_id,
        ps.name,
        ps.total_movies,
        ps.avg_production_year,
        ps.movie_titles,
        CASE 
            WHEN ps.total_movies > 10 THEN 'Highly Acclaimed'
            WHEN ps.total_movies BETWEEN 5 AND 10 THEN 'Moderately Known'
            ELSE 'Newcomer' 
        END AS actor_type
    FROM
        actor_stats ps
),
extended_infos AS (
    SELECT
        pi.person_id,
        COALESCE(pi.info, 'No Information') AS additional_info,
        pi.note
    FROM
        person_info pi
    LEFT JOIN
        famous_actors fa ON pi.person_id = fa.person_id
),
ranked_actors AS (
    SELECT
        fa.*, 
        RANK() OVER (ORDER BY fa.total_movies DESC, fa.avg_production_year DESC) AS actor_rank
    FROM
        famous_actors fa
)
SELECT
    ra.name AS actor_name,
    ra.total_movies,
    ra.avg_production_year,
    ra.actor_type,
    ei.additional_info,
    ei.note,
    CASE 
        WHEN ra.total_movies IS NULL THEN 'No Movies Found'
        ELSE 'Movies Found'
    END AS movie_status,
    CASE 
        WHEN ra.actor_rank <= 5 THEN 'Top Actor'
        ELSE 'Not Top Actor'
    END AS ranking_status
FROM
    ranked_actors ra
LEFT JOIN
    extended_infos ei ON ra.person_id = ei.person_id
WHERE
    ra.actor_rank IS NOT NULL 
    AND (ra.total_movies > 0 OR ei.additional_info IS NOT NULL)
ORDER BY
    ra.total_movies DESC, ra.avg_production_year ASC;
