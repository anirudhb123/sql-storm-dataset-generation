WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        array_agg(DISTINCT k.keyword) AS keywords,
        array_agg(DISTINCT c.name) AS companies,
        COUNT(DISTINCT a.person_id) AS cast_count
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
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info a ON cc.subject_id = a.id
    GROUP BY 
        t.id
),
PersonDetails AS (
    SELECT 
        a.person_id,
        a.name,
        array_agg(DISTINCT r.role) AS roles,
        array_agg(DISTINCT pi.info) AS person_info
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    GROUP BY 
        a.person_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.cast_count,
    pd.name AS actor_name,
    pd.roles,
    pd.person_info
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
