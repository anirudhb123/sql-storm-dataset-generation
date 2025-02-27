
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS alias_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS person_name,
        STRING_AGG(DISTINCT role.role, ', ') AS roles
    FROM 
        name p
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    LEFT JOIN 
        role_type role ON ci.role_id = role.id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.alias_names,
    md.keywords,
    pd.person_name,
    pd.roles
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id = md.movie_id
LEFT JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
