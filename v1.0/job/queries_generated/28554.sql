WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.kind) AS company_types,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, a.name, t.title, t.production_year, t.kind_id
),
CompanySummary AS (
    SELECT 
        company_id,
        COUNT(movie_id) AS movie_count,
        STRING_AGG(DISTINCT name, ', ') AS company_names
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        company_id
)
SELECT 
    md.aka_id,
    md.aka_name,
    md.movie_title,
    md.production_year,
    md.kind_id,
    md.keywords,
    cs.company_names,
    cs.movie_count,
    md.roles
FROM 
    MovieDetails md
LEFT JOIN 
    CompanySummary cs ON md.movie_title = cs.company_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year ASC, 
    md.movie_title ASC;
