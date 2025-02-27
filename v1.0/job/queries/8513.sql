
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title AS movie_title, 
        t.production_year, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        c.movie_id, 
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.title_id, 
    md.movie_title, 
    md.production_year, 
    md.keywords, 
    ad.actors, 
    md.companies
FROM 
    MovieDetails md
LEFT JOIN 
    ActorDetails ad ON md.title_id = ad.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC
LIMIT 100;
