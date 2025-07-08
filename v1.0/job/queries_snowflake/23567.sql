
WITH ranked_movies AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY mk.id) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
aggregated_actors AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_with_keyword AS (
    SELECT 
        t.title,
        t.production_year,
        rk.keyword,
        ra.actor_count,
        ra.actor_names
    FROM 
        title t
    LEFT JOIN 
        ranked_movies rk ON t.id = rk.movie_id AND rk.keyword_rank = 1
    LEFT JOIN 
        aggregated_actors ra ON t.id = ra.movie_id
    WHERE 
        t.production_year > 2000
),
famous_movies AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.keyword,
        mwk.actor_count,
        mwk.actor_names,
        COALESCE(mvi.info, 'No details') AS movie_info
    FROM 
        movie_with_keyword mwk
    LEFT JOIN 
        movie_info mvi ON mwk.production_year = mvi.movie_id 
        AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Academy Award Winning')
    WHERE 
        mwk.actor_count > (SELECT AVG(actor_count) FROM aggregated_actors)
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.actor_count,
    f.actor_names,
    CASE 
        WHEN f.actor_count IS NULL THEN 'Unknown Cast'
        ELSE 'Cast Details Available'
    END AS cast_information,
    LENGTH(f.title) AS title_length,
    CASE 
        WHEN f.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    TRIM(REPLACE(f.movie_info, 'No details', 'N/A')) AS cleaned_movie_info
FROM 
    famous_movies f
ORDER BY 
    f.production_year DESC,
    f.actor_count DESC
LIMIT 10;
