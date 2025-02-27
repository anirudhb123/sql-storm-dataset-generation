WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(*) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(*) > 5
),
keyword_usage AS (
    SELECT 
        t.id AS title_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    ku.keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    keyword_usage ku ON rt.id = ku.title_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, rt.cast_count DESC;
