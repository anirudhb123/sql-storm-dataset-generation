WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
popular_actors AS (
    SELECT
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    WHERE
        ci.nr_order = 1 -- Lead roles
    GROUP BY
        ak.name
    HAVING
        COUNT(ci.movie_id) > 3 -- Actors with more than 3 lead roles
)
SELECT
    rm.title AS movie_title,
    rm.production_year,
    ra.actor_name AS lead_actor,
    CASE 
        WHEN rm.rn = 1 THEN 'Most Popular'
        ELSE 'Other' 
    END AS popularity_rank,
    COALESCE(mk.keyword, 'No Keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT mi.info_type_id) FILTER (WHERE mi.info IS NOT NULL) AS non_null_info_count,
    ARRAY_AGG(DISTINCT CASE WHEN mi.info IS NOT NULL THEN mi.info END) AS non_null_info
FROM
    ranked_movies rm
LEFT JOIN
    popular_actors ra ON ra.movie_count > 3
LEFT JOIN
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN
    movie_info mi ON rm.movie_id = mi.movie_id
GROUP BY
    rm.movie_id, rm.title, rm.production_year, ra.actor_name, rm.rn
HAVING
    COUNT(DISTINCT mc.company_id) > 1 -- Only movies produced by more than one company
ORDER BY
    rm.production_year DESC, COUNT(DISTINCT mc.company_id) DESC, rm.title;
