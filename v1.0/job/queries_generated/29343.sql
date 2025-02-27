WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS movie_type,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    GROUP BY 
        t.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
full_movie_info AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.movie_type,
        md.actors,
        cd.companies,
        cd.company_types,
        md.keywords
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    movie_type,
    actors,
    companies,
    company_types,
    keywords
FROM 
    full_movie_info
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC,
    movie_title;
