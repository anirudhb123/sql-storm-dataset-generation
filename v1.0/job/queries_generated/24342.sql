WITH ranked_cast AS (
    SELECT
        cc.movie_id,
        ka.name AS actor_name,
        RANK() OVER (PARTITION BY cc.movie_id ORDER BY ka.name) AS actor_rank,
        COUNT(*) OVER (PARTITION BY cc.movie_id) AS total_actors
    FROM
        cast_info AS cc
    JOIN
        aka_name AS ka ON cc.person_id = ka.person_id
),
movie_years AS (
    SELECT
        m.id AS movie_id,
        m.production_year,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM
        aka_title AS m
    LEFT JOIN
        movie_info AS mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
),
keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
actor_movie_stats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM
        movie_companies AS mc
    JOIN
        company_name AS c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
)
SELECT
    m.movie_id,
    m.production_year,
    m.movie_info,
    COUNT(DISTINCT r.actor_name) AS actor_count,
    MAX(r.total_actors) AS max_actors_per_movie,
    CASE
        WHEN COUNT(DISTINCT r.actor_name) < 3 THEN 'Low Actor Count'
        WHEN COUNT(DISTINCT r.actor_name) BETWEEN 3 AND 10 THEN 'Moderate Actor Count'
        ELSE 'High Actor Count'
    END AS actor_category,
    COALESCE(kc.keyword_count, 0) AS num_keywords,
    acs.company_count,
    acs.companies
FROM
    movie_years AS m
LEFT JOIN
    ranked_cast AS r ON m.movie_id = r.movie_id
LEFT JOIN
    keyword_count AS kc ON m.movie_id = kc.movie_id
LEFT JOIN
    actor_movie_stats AS acs ON m.movie_id = acs.movie_id
GROUP BY
    m.movie_id, m.production_year, m.movie_info, acs.company_count, acs.companies
HAVING
    m.production_year > 2000 AND (COUNT(DISTINCT r.actor_name) IS NULL OR COUNT(DISTINCT r.actor_name) > 1)
ORDER BY
    m.production_year DESC, actor_count DESC NULLS LAST;
