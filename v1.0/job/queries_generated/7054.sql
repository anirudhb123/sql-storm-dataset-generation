WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        c.name AS company_name, 
        d.name AS director_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name d ON ci.person_id = d.person_id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.keyword, 
    COUNT(md.company_name) AS company_count, 
    STRING_AGG(DISTINCT md.director_name, ', ') AS directors 
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.keyword
ORDER BY 
    md.production_year DESC, 
    company_count DESC;
