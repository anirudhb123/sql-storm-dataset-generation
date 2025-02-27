WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        JSON_ARRAYAGG(DISTINCT c.name) AS companies
    FROM 
        aka_title ak 
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id
),
RoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT CASE WHEN r.role = 'Director' THEN ci.person_id END) AS director_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    rc.actor_count,
    rc.director_count,
    ROUND(AVG(md.production_year), 2) AS average_year
FROM 
    MovieDetails md
LEFT JOIN 
    RoleCounts rc ON md.movie_id = rc.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, rc.actor_count DESC
LIMIT 10;
