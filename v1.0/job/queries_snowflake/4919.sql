
WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
company_movies AS (
    SELECT 
        mc.movie_id,
        MIN(CASE WHEN ct.kind = 'Producer' THEN cn.name END) AS producer_name,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
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
    rm.title_id,
    rm.title,
    rm.production_year,
    cm.producer_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.year_rank = 1 THEN 'Latest Movie'
        ELSE 'Older Movie'
    END AS movie_status,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rm.title_id) AS complete_cast_count
FROM 
    ranked_movies rm
LEFT JOIN 
    company_movies cm ON rm.title_id = cm.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.title_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
