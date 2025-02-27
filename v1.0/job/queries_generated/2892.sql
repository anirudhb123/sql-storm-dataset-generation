WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id, 
        title.title AS movie_title, 
        title.production_year, 
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC, title.title ASC) AS rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
company_info AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
keyword_summary AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    COALESCE(cs.kind, 'Unknown') AS cast_type,
    COALESCE(kw.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.company_name) AS total_companies,
    SUM(CASE WHEN rm.rank <= 10 THEN 1 ELSE 0 END) OVER () AS top_rank_movies
FROM 
    ranked_movies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    comp_cast_type cs ON cc.role_id = cs.id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    keyword_summary kw ON rm.movie_id = kw.movie_id
GROUP BY 
    rm.movie_id, rm.movie_title, rm.production_year, ci.company_name, cs.kind, kw.keywords
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
