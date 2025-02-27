WITH MovieInfo AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyInfo AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
)
SELECT
    mi.movie_title,
    mi.production_year,
    mi.actor_names,
    mi.keywords,
    ci.company_names,
    ci.company_types
FROM 
    MovieInfo mi
LEFT JOIN 
    CompanyInfo ci ON mi.movie_id = ci.movie_id
ORDER BY 
    mi.production_year DESC,
    mi.movie_title;
