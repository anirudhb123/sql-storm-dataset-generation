WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movies_with_actors AS (
    SELECT 
        mc.movie_id,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        actor_counts ac ON mc.movie_id = ac.movie_id
),
titles_with_cast AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        mw.actor_count,
        CASE
            WHEN mw.actor_count >= 5 THEN 'Major Cast'
            WHEN mw.actor_count = 0 THEN 'No Cast'
            ELSE 'Minor Cast'
        END AS cast_category
    FROM 
        ranked_titles rt
    LEFT JOIN 
        movies_with_actors mw ON rt.title_id = mw.movie_id
)
SELECT 
    twc.title,
    twc.production_year,
    twc.cast_category,
    twc.actor_count,
    CASE
        WHEN twc.production_year < 1950 THEN 'Classic Era'
        WHEN twc.production_year BETWEEN 1950 AND 2000 THEN 'Modern Era'
        ELSE 'Contemporary Era'
    END AS era,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    titles_with_cast twc
LEFT JOIN 
    movie_companies mc ON twc.title_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    twc.actor_count IS NOT NULL
GROUP BY 
    twc.title, twc.production_year, twc.cast_category, twc.actor_count
HAVING 
    twc.actor_count = (SELECT MAX(actor_count) FROM movies_with_actors)
ORDER BY 
    twc.production_year DESC, 
    twc.title ASC 
LIMIT 10;
