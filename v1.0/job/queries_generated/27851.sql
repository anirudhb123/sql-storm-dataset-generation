WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
top_cast AS (
    SELECT 
        ci.movie_id, 
        COUNT(ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
    HAVING 
        COUNT(ci.person_id) > 5
),
detailed_movie_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.company_name,
        ci.cast_count,
        rt.role
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        top_cast ci ON t.id = ci.movie_id
    JOIN 
        cast_info cast ON cast.movie_id = t.id
    JOIN 
        role_type rt ON cast.role_id = rt.id
    WHERE 
        t.production_year = 2020
)
SELECT 
    d.title, 
    d.production_year, 
    d.company_name, 
    d.cast_count, 
    STRING_AGG(DISTINCT rt.role, ', ') AS roles
FROM 
    detailed_movie_info d
JOIN 
    ranked_titles rt ON d.title_id = rt.title_id
WHERE 
    rt.rank_by_year <= 10
GROUP BY 
    d.title, d.production_year, d.company_name, d.cast_count
ORDER BY 
    d.production_year DESC, 
    d.cast_count DESC;
