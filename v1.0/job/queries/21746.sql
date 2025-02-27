
WITH actor_movie_count AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id
),
high_profile_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT c.company_id) AS company_count,
        CASE 
            WHEN COUNT(DISTINCT c.company_id) = 0 THEN 'Independent'
            WHEN COUNT(DISTINCT c.company_id) > 5 THEN 'Blockbuster'
            ELSE 'Moderate'
        END AS movie_category
    FROM
        aka_title m
    LEFT JOIN
        movie_companies c ON m.id = c.movie_id
    LEFT JOIN
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
actor_award_candidates AS (
    SELECT
        an.id,
        an.name,
        amc.movie_count,
        CASE 
            WHEN amc.movie_count > 0 AND amc.movie_count < 5 THEN TRUE
            ELSE FALSE
        END AS qualified_for_award
    FROM 
        aka_name an
    JOIN
        actor_movie_count amc ON an.person_id = amc.person_id
    WHERE
        an.name IS NOT NULL AND an.name <> ''
)
SELECT
    h.title,
    h.production_year,
    h.actor_names,
    h.movie_category,
    a.name AS award_candidate,
    a.qualified_for_award
FROM
    high_profile_movies h
LEFT JOIN
    actor_award_candidates a ON a.movie_count > 0
WHERE
    (h.movie_category = 'Blockbuster' OR h.movie_category = 'Moderate')
    AND EXISTS (
        SELECT 1 FROM movie_keyword mk 
        WHERE mk.movie_id = h.movie_id 
        AND mk.keyword_id IN (
            SELECT k.id FROM keyword k WHERE LOWER(k.keyword) LIKE LOWER('%action%')
        )
    )
ORDER BY 
    h.production_year DESC,
    h.title ASC
LIMIT 10;
