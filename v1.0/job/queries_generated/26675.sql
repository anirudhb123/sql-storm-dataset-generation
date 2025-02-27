WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        STRING_AGG(DISTINCT c.name, ', ') AS cast 
    FROM 
        aka_title t 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        GROUP_CONCAT(DISTINCT pi.info) AS person_info
    FROM 
        name p 
    LEFT JOIN 
        person_info pi ON p.id = pi.person_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    pd.name AS actor_name,
    pd.person_info
FROM 
    MovieDetails md 
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id 
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
WHERE 
    md.production_year >= 1990
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 50;
