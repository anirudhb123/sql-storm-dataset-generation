WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank_by_cast <= 5
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        ci.company_name,
        ci.company_type,
        CASE 
            WHEN ci.company_name IS NULL THEN 'Independent'
            ELSE ci.company_name 
        END AS finalized_company_name
    FROM 
        top_movies tm
    LEFT JOIN 
        company_info ci ON tm.production_year = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.finalized_company_name,
    COALESCE(SUM(mi.info::integer), 0) AS keyword_count
FROM 
    movie_details md
LEFT JOIN 
    movie_keyword mk ON md.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
LEFT JOIN 
    movie_info mi ON md.production_year = mi.movie_id
WHERE 
    md.production_year IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.finalized_company_name
HAVING 
    COUNT(mk.keyword_id) > 0
ORDER BY 
    md.production_year DESC, keyword_count DESC;
