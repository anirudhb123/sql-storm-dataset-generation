
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_kinds
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.title_id,
        mi.info AS movie_info
    FROM 
        MovieDetails m
    JOIN 
        movie_info mi ON m.title_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Synopsis', 'Awards'))
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    STRING_AGG(DISTINCT mi.movie_info, ', ') AS additional_info
FROM 
    MovieDetails md
LEFT JOIN 
    MovieInfo mi ON md.title_id = mi.title_id
GROUP BY 
    md.title, md.production_year, md.actor_names
ORDER BY 
    md.production_year DESC, md.title;
