WITH movie_analysis AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ca.nr_order::text, ', ') AS order_of_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    LEFT JOIN 
        name p ON ca.person_id = p.id
    LEFT JOIN 
        role_type r ON ca.role_id = r.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, p.name, r.role
),
keyword_analysis AS (
    SELECT 
        movie_id, 
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        movie_analysis
    GROUP BY 
        movie_id
)
SELECT 
    ma.movie_id,
    ma.movie_title,
    ma.production_year,
    ma.company_name,
    ma.person_name,
    ma.person_role,
    ka.keywords,
    ma.cast_count,
    ma.order_of_cast
FROM 
    movie_analysis ma
JOIN 
    keyword_analysis ka ON ma.movie_id = ka.movie_id
ORDER BY 
    ma.production_year DESC, 
    ma.movie_title;
