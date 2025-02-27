
WITH movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        STRING_AGG(DISTINCT CAST(c.person_id AS TEXT), ', ') AS cast_ids,
        STRING_AGG(DISTINCT CAST(c.person_role_id AS TEXT), ', ') AS role_ids,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cp.kind, ', ') AS company_types,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        movie_companies m ON a.id = m.movie_id
    JOIN 
        company_type cp ON m.company_type_id = cp.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
person_details AS (
    SELECT 
        p.id AS person_id,
        p.name,
        STRING_AGG(DISTINCT d.title, ', ') AS movies,
        STRING_AGG(DISTINCT CAST(d.production_year AS TEXT), ', ') AS production_years,
        COUNT(DISTINCT d.movie_id) AS movie_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.id = ci.person_id
    JOIN 
        movie_details d ON ci.movie_id = d.movie_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    p.name AS actor_name,
    p.movie_count AS total_movies,
    d.title AS movie_title,
    d.production_year AS year_released,
    d.cast_ids AS cast_ids,
    d.role_ids AS role_ids,
    d.keywords AS associated_keywords,
    d.company_types AS production_companies,
    d.company_count AS total_companies
FROM 
    person_details p
JOIN 
    movie_details d ON p.movies LIKE '%' || d.title || '%'
ORDER BY 
    p.movie_count DESC, p.name ASC;
