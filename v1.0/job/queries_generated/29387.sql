WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(comp.name, 'Unknown Company') AS company_name,
        COALESCE(cast.name, 'Unknown Cast') AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        aka_name cast ON cc.subject_id = cast.id
    GROUP BY 
        m.id, m.title, m.production_year, comp.name
),
DirectorInfo AS (
    SELECT 
        d.movie_id,
        STRING_AGG(DISTINCT d.cast_name, ', ') AS directors
    FROM (
        SELECT 
            mc.movie_id, 
            a.name AS cast_name
        FROM 
            cast_info ci
        JOIN 
            aka_name a ON ci.person_id = a.person_id
        JOIN 
            role_type r ON ci.role_id = r.id
        WHERE 
            r.role ILIKE '%director%'
    ) d
    GROUP BY d.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.keywords,
    m.company_name,
    m.cast_names,
    d.directors
FROM 
    MovieInfo m
LEFT JOIN 
    DirectorInfo d ON m.movie_id = d.movie_id
ORDER BY 
    m.production_year DESC, 
    m.title;
