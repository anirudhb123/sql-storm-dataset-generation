WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.kind AS company_type,
        COALESCE(NULLIF(c.name, ''), 'Unknown') AS company_name
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
    GROUP BY 
        t.id, t.title, t.production_year, c.kind, c.name
),
CompleteCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.company_type,
        md.company_name,
        cc.total_cast,
        cc.cast_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompleteCast cc ON md.movie_id = cc.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.keywords,
    dmi.company_type,
    dmi.company_name,
    dmi.total_cast,
    dmi.cast_names
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_year BETWEEN 2000 AND 2020
ORDER BY 
    dmi.production_year DESC,
    dmi.title ASC;
