WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        c.role_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, c.role_id
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    cd.company_names,
    cd.company_types,
    md.cast_count
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year BETWEEN 1990 AND 2020
AND 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
