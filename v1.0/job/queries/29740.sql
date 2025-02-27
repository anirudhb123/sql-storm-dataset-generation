WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.kind_id,
    cc.company_count,
    kc.keyword_count
FROM 
    ranked_titles rt
LEFT JOIN 
    company_counts cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    keyword_counts kc ON rt.title_id = kc.movie_id
WHERE 
    rt.rank_per_year <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.kind_id;
