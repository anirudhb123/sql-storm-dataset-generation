
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(c.character_name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        keyword k ON m.id = k.id
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            STRING_AGG(DISTINCT a.name, ', ') AS character_name
        FROM 
            cast_info ci
        JOIN 
            aka_name a ON ci.person_id = a.person_id
        GROUP BY 
            ci.movie_id
    ) c ON c.movie_id = m.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    cd.companies_involved
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
