WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank_keyword
    FROM 
        aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
top_actors AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(*) AS num_movies
    FROM 
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
    HAVING 
        COUNT(*) > 5
),
movie_info_aggregated AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS all_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ra.actor_name,
    ma.all_info,
    rt.keyword
FROM 
    ranked_titles rt
JOIN top_actors ra ON rt.title_id = ra.movie_id
JOIN movie_info_aggregated ma ON rt.title_id = ma.movie_id
WHERE 
    rt.rank_keyword = 1
ORDER BY 
    rt.production_year DESC, ra.num_movies DESC;
