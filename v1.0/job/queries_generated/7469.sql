WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.id) AS company_count,
        COUNT(DISTINCT ca.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    MD.movie_id,
    MD.title,
    MD.production_year,
    MD.actors,
    MD.company_types,
    MD.keywords,
    MD.company_count,
    MD.cast_count
FROM 
    MovieData MD
WHERE 
    MD.production_year >= 2000
ORDER BY 
    MD.production_year DESC, MD.title;
