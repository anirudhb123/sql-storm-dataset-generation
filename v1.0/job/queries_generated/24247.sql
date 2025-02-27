WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT
        c.person_id,
        c.movie_id,
        COUNT(c.role_id) AS roles_count
    FROM cast_info c
    WHERE c.note IS NULL
    GROUP BY c.person_id, c.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_movie_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
combined_data AS (
    SELECT
        t.title,
        t.production_year,
        COALESCE(mkc.keywords, 'No Keywords') AS keywords,
        COALESCE(ac.actors_count, 0) AS actors_count,
        COALESCE(cm.company_count, 0) AS company_count,
        rt.title_rank
    FROM title t
    LEFT JOIN movie_keywords mkc ON t.id = mkc.movie_id
    LEFT JOIN (
        SELECT
            am.movie_id,
            SUM(am.roles_count) AS actors_count
        FROM actor_movies am
        GROUP BY am.movie_id
    ) ac ON t.id = ac.movie_id
    LEFT JOIN company_movie_counts cm ON t.id = cm.movie_id
    LEFT JOIN ranked_titles rt ON t.id = rt.title_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.keywords,
    cd.actors_count,
    cd.company_count,
    CASE 
        WHEN cd.actors_count > 5 THEN 'Ensemble Cast'
        WHEN cd.actors_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_size,
    CASE 
        WHEN cd.keywords LIKE '%Action%' THEN 'Action-Packed'
        WHEN cd.keywords LIKE '%Drama%' THEN 'Dramatic'
        ELSE 'Other Genre'
    END AS genre_assessment
FROM combined_data cd
WHERE cd.production_year > 1990
ORDER BY cd.production_year DESC, cd.title_rank
LIMIT 100
OFFSET 50;
