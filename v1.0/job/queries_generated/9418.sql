WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_roles
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), ranked_actors AS (
    SELECT 
        a.id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.id, a.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    ra.name AS actor_name,
    ra.movies_count,
    ra.total_roles,
    (rm.keyword_count * ra.movies_count) AS performance_metric
FROM 
    ranked_movies rm
JOIN 
    ranked_actors ra ON rm.keyword_count > 5 AND ra.movies_count > 3
ORDER BY 
    performance_metric DESC, rm.production_year DESC
LIMIT 50;
