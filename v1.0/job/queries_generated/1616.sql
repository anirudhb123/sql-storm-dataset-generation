WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    cd.company_names,
    cd.company_type,
    CASE 
        WHEN cd.company_type IS NULL THEN 'Independent'
        ELSE cd.company_type 
    END AS final_company_type
FROM 
    top_movies tm
LEFT JOIN 
    company_details cd ON tm.title = cd.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = tm.id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
    )
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
