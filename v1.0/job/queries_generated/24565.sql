WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actor_summary AS (
    SELECT 
        a.person_id,
        a.id AS actor_id,
        na.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM aka_name na
    JOIN cast_info ci ON na.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY a.person_id, na.name, a.id
),
recent_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mcm.company_id,
        cn.name AS company_name
    FROM aka_title at
    JOIN movie_companies mcm ON at.movie_id = mcm.movie_id
    JOIN company_name cn ON mcm.company_id = cn.id
    JOIN (
        SELECT 
            DISTINCT production_year
        FROM title
        WHERE production_year >= (SELECT MAX(production_year) - 10 FROM title)
    ) recent ON at.production_year = recent.production_year
    WHERE at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
aggregated_data AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        COALESCE(asum.movie_count, 0) AS total_actors,
        COALESCE(mc.company_count, 0) AS total_companies
    FROM ranked_titles rt
    LEFT JOIN (
        SELECT 
            production_year,
            COUNT(DISTINCT ci.person_id) AS movie_count
        FROM cast_info ci
        JOIN title t ON ci.movie_id = t.id
        GROUP BY production_year
    ) asum ON rt.production_year = asum.production_year
    LEFT JOIN (
        SELECT 
            mcm.movie_id,
            COUNT(DISTINCT mcm.company_id) AS company_count
        FROM movie_companies mcm
        GROUP BY mcm.movie_id
    ) mc ON rt.title_id = mc.movie_id
    WHERE rt.title_rank = 1
)
SELECT 
    ad.movie_title,
    ad.production_year,
    ad.total_actors,
    ad.total_companies,
    CASE 
        WHEN ad.total_actors IS NULL AND ad.total_companies IS NULL THEN 'No data'
        WHEN ad.total_actors IS NOT NULL AND ad.total_companies IS NOT NULL THEN CONCAT('Actors: ', ad.total_actors, ', Companies: ', ad.total_companies)
        ELSE 'Some data is missing'
    END AS summary_info
FROM aggregated_data ad
JOIN recent_movies rm ON ad.movie_title = rm.title
ORDER BY ad.production_year DESC, ad.total_actors DESC NULLS LAST;
