WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword,
        a.name AS actor_name
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN aka_name a ON cc.subject_id = a.person_id
)
SELECT 
    md.movie_title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_type, ', ') AS companies
FROM MovieDetails md
GROUP BY md.movie_title, md.production_year
ORDER BY md.production_year DESC, md.movie_title;
