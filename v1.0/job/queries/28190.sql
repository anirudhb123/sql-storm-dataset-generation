WITH ranked_movies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    WHERE
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY
        a.id, a.title, a.production_year, a.kind_id
),
ranked_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
enhanced_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rc.company_count,
        rm.actor_names,
        rc.company_names
    FROM
        ranked_movies rm
    LEFT JOIN
        ranked_companies rc ON rm.movie_id = rc.movie_id
)
SELECT
    em.title,
    em.production_year,
    em.cast_count,
    em.company_count,
    em.actor_names,
    em.company_names
FROM
    enhanced_movies em
WHERE
    em.cast_count > 5 AND em.company_count > 2
ORDER BY
    em.production_year DESC, em.cast_count DESC;
