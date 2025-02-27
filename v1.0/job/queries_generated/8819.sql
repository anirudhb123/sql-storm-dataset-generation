WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        COUNT(ki.keyword) AS keyword_count,
        COUNT(DISTINCT a.name) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.title, t.production_year, c.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_type,
    md.keyword_count,
    md.actor_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC, 
    md.actor_count DESC
LIMIT 50;
