
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        a.id AS person_id,
        a.name AS person_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.id, a.name
)
SELECT 
    md.movie_title,
    md.production_year,
    pd.person_name,
    pd.roles,
    md.keywords,
    md.companies
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    PersonDetails pd ON cc.subject_id = pd.person_id
ORDER BY 
    md.production_year DESC, md.movie_title;
