WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
person_details AS (
    SELECT 
        a.name AS actor_name,
        GROUP_CONCAT(DISTINCT r.role) AS roles,
        COUNT(DISTINCT ci.id) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_names,
    md.keywords,
    md.cast_count,
    pd.actor_name,
    pd.roles,
    pd.total_movies
FROM 
    movie_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_details pd ON a.id = pd.id
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC, 
    pd.total_movies DESC;
