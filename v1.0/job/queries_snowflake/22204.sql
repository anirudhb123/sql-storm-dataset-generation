
WITH recursive ranked_titles AS (
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
cast_details AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COUNT(DISTINCT a.id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movie_info_with_keywords AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    tt.title AS movie_title,
    tt.production_year,
    cd.cast_names,
    cd.cast_count,
    cp.company_names,
    cp.company_count,
    mk.keywords,
    COALESCE(tt.title_rank, -1) AS title_rank
FROM 
    ranked_titles tt
LEFT JOIN 
    cast_details cd ON tt.title_id = cd.movie_id
LEFT JOIN 
    company_details cp ON tt.title_id = cp.movie_id
LEFT JOIN 
    movie_info_with_keywords mk ON tt.title_id = mk.movie_id
WHERE 
    (tt.production_year >= 2000 OR mk.keywords IS NOT NULL)
    AND (cd.cast_count > 3 OR cp.company_count IS NULL)
ORDER BY 
    tt.production_year DESC,
    cd.cast_count DESC,
    tt.title;
