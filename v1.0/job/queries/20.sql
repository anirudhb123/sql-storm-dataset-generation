WITH movie_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mr.role_count, 0) AS total_roles,
    cm.company_name,
    cm.company_type,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS total_keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_roles mr ON rm.movie_id = mr.movie_id
LEFT JOIN 
    company_movies cm ON rm.movie_id = cm.movie_id
WHERE 
    rn <= 10
ORDER BY 
    rm.production_year DESC, rm.movie_id;
