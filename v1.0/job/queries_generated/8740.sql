WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.name, k.keyword, a.name
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ARRAY_AGG(DISTINCT md.company_name) AS companies,
    ARRAY_AGG(DISTINCT md.keyword) AS keywords,
    ARRAY_AGG(DISTINCT md.actor_name) AS actors,
    md.company_count
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_count
ORDER BY 
    md.production_year DESC, md.title;
