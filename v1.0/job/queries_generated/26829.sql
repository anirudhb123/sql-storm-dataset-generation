WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(MAX(k.keyword), 'No Keywords') AS keyword,
        c.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COALESCE(mi.info, 'N/A')) AS info_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY
        t.id, t.title, t.production_year, c.kind
), top_movies AS (
    SELECT 
        title,
        production_year,
        keyword,
        company_type
    FROM 
        ranked_movies
    WHERE 
        info_rank = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.company_type,
    COUNT(ci.id) AS cast_count
FROM 
    top_movies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT t.id FROM title t WHERE t.title = tm.title)
GROUP BY 
    tm.title, tm.production_year, tm.keyword, tm.company_type
ORDER BY 
    tm.production_year DESC, cast_count DESC
LIMIT 10;
