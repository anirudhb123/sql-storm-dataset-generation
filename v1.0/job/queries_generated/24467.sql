WITH RECURSIVE movie_employee_roles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT e.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_employee_roles e ON t.id = e.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, m.name
),
title_years AS (
    SELECT
        movie_id,
        MIN(extract(YEAR FROM mv.production_year)) AS first_year,
        MAX(extract(YEAR FROM mv.production_year)) AS last_year
    FROM 
        aka_title mv
    LEFT JOIN 
        ranked_movies rm ON mv.id = rm.movie_id
    WHERE 
        rm.rank_by_cast_size <= 10
    GROUP BY 
        movie_id
),
final_movie_list AS (
    SELECT 
        t.title,
        CASE 
            WHEN ty.first_year IS NULL THEN 'Unknown'
            ELSE ty.first_year::text || ' - ' || ty.last_year::text
        END AS production_span,
        COALESCE(m.keywords, 'No keywords') AS movie_keywords
    FROM 
        ranked_movies t
    LEFT JOIN 
        title_years ty ON t.movie_id = ty.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords 
         FROM 
            movie_keyword mk
         JOIN 
            keyword k ON mk.keyword_id = k.id
         GROUP BY 
            movie_id) m ON m.movie_id = t.movie_id
    WHERE 
        t.rank_by_cast_size <= 10
)
SELECT 
    fml.title,
    fml.production_span,
    fml.movie_keywords,
    CASE 
        WHEN fml.production_span LIKE '%Unknown%' THEN 'Needs Further Research'
        ELSE 'Well Documented'
    END AS documentation_status,
    RANK() OVER (ORDER BY fml.production_span DESC) AS overall_rank
FROM 
    final_movie_list fml
WHERE 
    fml.production_span IS NOT NULL
ORDER BY 
    overall_rank
LIMIT 20;
