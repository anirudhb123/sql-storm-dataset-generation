
WITH ranked_movies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_per_year,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies_per_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COALESCE(ct.kind, 'Unknown') AS role_type,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        comp_cast_type ct ON ct.id = ci.role_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, '; ') AS concatenated_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role_type,
    cd.actor_rank,
    COALESCE(mid.concatenated_info, 'No Info') AS movie_details,
    COALESCE(ks.keywords, 'No Keywords') AS keyword_list,
    CASE 
        WHEN rm.total_movies_per_year = 1 THEN 'Solo Release' 
        WHEN rm.rank_per_year = 1 THEN 'Top Movie of Year!'
        WHEN rm.rank_per_year <= 5 THEN 'In the Top 5' 
        ELSE 'Regular Release' 
    END AS ranking_comment
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON cd.movie_id = rm.title_id AND cd.actor_rank = 1
LEFT JOIN 
    movie_info_details mid ON mid.movie_id = rm.title_id
LEFT JOIN 
    keyword_summary ks ON ks.movie_id = rm.title_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, rm.title;
