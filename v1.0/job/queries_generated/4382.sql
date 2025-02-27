WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        DISTINCT ci.movie_id, 
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        ar.role_count,
        COALESCE(mg.name, 'Unknown') AS company_name
    FROM 
        ranked_movies m
    LEFT JOIN 
        actor_roles ar ON m.title = (SELECT title FROM aka_title WHERE id = m.id)
    LEFT JOIN 
        movie_companies mc ON m.production_year = mc.movie_id
    LEFT JOIN 
        company_name mg ON mc.company_id = mg.id
    WHERE 
        ar.role_count > 1
)
SELECT 
    md.title,
    md.production_year,
    md.role_count,
    COUNT(*) OVER (PARTITION BY md.production_year) AS movie_count_in_year,
    STRING_AGG(DISTINCT md.company_name, ', ') AS companies
FROM 
    movie_details md
WHERE 
    md.role_count IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.role_count
ORDER BY 
    md.production_year DESC, md.role_count DESC;
