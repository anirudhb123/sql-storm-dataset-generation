WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS companies,
        COALESCE(STRING_AGG(DISTINCT p.name, ', '), 'No Cast') AS cast_names,
        COUNT(DISTINCT p.id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.cast_names,
    md.cast_count
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 50;
