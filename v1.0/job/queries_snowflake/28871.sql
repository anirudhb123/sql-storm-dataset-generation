
WITH movie_stats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        t.id AS movie_id
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
        AND (LOWER(t.title) LIKE '%action%' OR LOWER(t.title) LIKE '%adventure%')
    GROUP BY 
        t.title, t.production_year, t.id
),
company_stats AS (
    SELECT
        m.movie_id,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS production_companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        c.country_code = 'USA'
    GROUP BY 
        m.movie_id
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    cs.production_companies,
    ms.keywords
FROM 
    movie_stats ms
LEFT JOIN 
    company_stats cs ON ms.movie_id = cs.movie_id
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC
LIMIT 20;
