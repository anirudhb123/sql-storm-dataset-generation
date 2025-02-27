WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_cast,
        COALESCE(AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE NULL END), 0) AS avg_info_length
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
title_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    INNER JOIN 
        keyword kw ON mt.keyword_id = kw.id
    GROUP BY 
        mt.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS num_companies,
        MAX(co.name) AS main_company
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank_per_year,
        rm.total_cast,
        rm.avg_info_length,
        COALESCE(tk.keywords, 'No Keywords') AS keywords,
        COALESCE(mci.num_companies, 0) AS num_companies,
        COALESCE(mci.main_company, 'N/A') AS main_company
    FROM 
        ranked_movies rm
    LEFT JOIN 
        title_keywords tk ON rm.movie_id = tk.movie_id
    LEFT JOIN 
        movie_company_info mci ON rm.movie_id = mci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.avg_info_length,
    md.keywords,
    md.num_companies,
    md.main_company
FROM 
    movie_details md
WHERE 
    md.rank_per_year <= 5 AND 
    md.avg_info_length IS NOT NULL AND 
    (md.keywords LIKE '%action%' OR md.keywords LIKE '%drama%')
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC
LIMIT 100;
