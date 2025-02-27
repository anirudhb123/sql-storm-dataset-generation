WITH RECURSIVE movie_ranking AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON c.movie_id = t.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
    
    UNION ALL
    
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count + 1
    FROM
        movie_ranking m
    WHERE
        m.actor_count > 0
)

SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_count,
    COALESCE(p.info, 'No Information') AS actor_info,
    CASE
        WHEN m.actor_count > 10 THEN 'High'
        WHEN m.actor_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS popularity_level
FROM
    movie_ranking m
LEFT JOIN (
    SELECT
        c.movie_id,
        STRING_AGG(DISTINCT pi.info, ', ') AS info
    FROM
        cast_info c
    JOIN
        person_info pi ON pi.person_id = c.person_id
    GROUP BY
        c.movie_id
) p ON p.movie_id = m.movie_id
ORDER BY
    m.actor_count DESC, m.production_year DESC
LIMIT 50;

-- Additional analysis using window functions
SELECT
    movie_id,
    title,
    production_year,
    actor_count,
    RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank_within_year,
    DENSE_RANK() OVER (ORDER BY actor_count DESC) AS overall_rank
FROM
    movie_ranking
WHERE
    actor_count IS NOT NULL;

-- Example of NULL handling and string manipulation
SELECT
    m.id AS movie_id,
    m.title,
    COALESCE(mc.name, 'Unknown Company') AS company_name,
    CASE
        WHEN m.production_year < 2010 THEN 'Pre-2010'
        ELSE 'Post-2010'
    END AS production_period
FROM
    aka_title m
LEFT JOIN
    movie_companies mc ON mc.movie_id = m.id
WHERE
    m.title LIKE '%Action%'
ORDER BY
    production_period, m.title;
