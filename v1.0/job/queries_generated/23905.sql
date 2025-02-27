WITH recursive movie_years AS (
    SELECT DISTINCT production_year
    FROM aka_title
    WHERE production_year IS NOT NULL
),
ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rn
    FROM aka_title m
    JOIN movie_keyword mk ON mk.movie_id = m.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%action%'
),
actor_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name a ON a.person_id = ci.person_id
    WHERE a.name IS NOT NULL
    GROUP BY ci.movie_id
),
movie_stats AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(ac.actor_count, 0) AS total_actors,
        CASE 
            WHEN r.rn = 1 THEN 'Latest'
            ELSE 'Not Latest'
        END AS movie_status
    FROM ranked_movies r
    LEFT JOIN actor_counts ac ON ac.movie_id = r.movie_id
    WHERE r.production_year IS NOT NULL
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.total_actors,
    COALESCE(NULLIF(m.movie_status, 'Latest'), 'Unknown') AS status
FROM movie_stats m
WHERE m.production_year IN (SELECT * FROM movie_years WHERE production_year > 1990)
ORDER BY m.total_actors DESC, m.production_year DESC
LIMIT 50;

-- Additional complexities:
-- 1. The recursive CTE `movie_years` ensures we have a set of distinct production years.
-- 2. The `ranked_movies` CTE ranks movies within each production year, enabling us to identify the latest movies easily.
-- 3. The `actor_counts` CTE aggregates actor counts per movie, accounting for potential NULLs if there are no associated actors.
-- 4. The main query then filters for movies produced after 1990, sorting them by actor count and production year, and adding complexity with CASE and COALESCE for nuanced status visibility.
-- 5. Combining string comparisons with ILIKE brings implicit handling of case sensitivity, while NULL logic and COALESCE ensure no unexpected NULLs lead to dropped results.
