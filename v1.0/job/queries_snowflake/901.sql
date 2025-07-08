
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS title_rank,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_movie_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
selected_movies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cm.company_count
    FROM 
        ranked_titles rt
    LEFT JOIN 
        company_movie_counts cm ON rt.title_id = cm.movie_id
    WHERE 
        rt.title_rank = 1
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    sm.title,
    sm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(sm.company_count, 0) AS company_count
FROM 
    selected_movies sm
LEFT JOIN 
    movie_keywords mk ON sm.title_id = mk.movie_id
ORDER BY 
    sm.production_year DESC, sm.title ASC;
