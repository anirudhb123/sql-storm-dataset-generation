
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        ak.person_id AS person_id,
        ak.name AS aka_name,
        r.role,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ak.person_id, ak.name, r.role
)
SELECT 
    md.title,
    md.production_year,
    ARRAY_TO_STRING(md.keywords, ', ') AS keywords,
    ARRAY_TO_STRING(md.companies, ', ') AS companies,
    pd.aka_name,
    pd.role,
    pd.movie_count
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
ORDER BY 
    md.production_year DESC, pd.movie_count DESC
LIMIT 100;
