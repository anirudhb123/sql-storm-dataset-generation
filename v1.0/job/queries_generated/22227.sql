WITH recursive actor_movies AS (
    SELECT
        a.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS recent_movie_rank,
        COUNT(*) OVER (PARTITION BY a.person_id) AS total_movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    WHERE t.kind_id IN (1, 2) -- assuming 1 = feature, 2 = documentary
    AND t.production_year >= 2000
),
company_movies AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        mt.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type mt ON mc.company_type_id = mt.id
    GROUP BY mc.movie_id
),
ranked_movies AS (
    SELECT 
        am.person_id,
        am.title,
        am.production_year,
        cm.company_names,
        cm.company_type,
        am.recent_movie_rank,
        am.total_movies,
        CASE 
            WHEN am.total_movies > 5 THEN 'Frequent Actor'
            WHEN am.total_movies BETWEEN 3 AND 5 THEN 'Moderate Actor'
            ELSE 'Rare Actor'
        END AS actor_frequency
    FROM actor_movies am
    LEFT JOIN company_movies cm ON am.title = cm.movie_id
)
SELECT 
    r.person_id,
    COUNT(*) FILTER (WHERE r.actor_frequency = 'Frequent Actor') AS frequent_actor_count,
    COUNT(DISTINCT r.title) AS distinct_movies,
    MAX(r.production_year) AS last_movie_year,
    ARRAY_AGG(DISTINCT r.company_names) FILTER (WHERE r.company_names IS NOT NULL) AS companies_involved
FROM ranked_movies r
GROUP BY r.person_id
HAVING COUNT(DISTINCT r.title) > 1
ORDER BY last_movie_year DESC
LIMIT 10;

-- Additional consideration: Testing NULL semantics
SELECT 
    r.person_id,
    COALESCE(MAX(r.company_names), 'No Companies') AS companies_involved,
    COUNT(*) AS movie_count
FROM ranked_movies r
LEFT JOIN company_movies cm ON r.title = cm.movie_id
GROUP BY r.person_id
HAVING COUNT(*) > 0 -- Filter for actors who have acted in at least one movie
ORDER BY movie_count DESC;
