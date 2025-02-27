WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT aka.name, ', ') AS aliases,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cct.kind, ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type cct ON mc.company_type_id = cct.id
    LEFT JOIN 
        aka_name aka ON aka.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = t.id)
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
CastInfo AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aliases,
    md.keywords,
    ci.cast_members,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    MovieDetails md
LEFT JOIN 
    CastInfo ci ON md.id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON md.id = mc.movie_id
GROUP BY 
    md.movie_title, md.production_year, md.aliases, ci.cast_members
ORDER BY 
    md.production_year DESC, md.movie_title;
