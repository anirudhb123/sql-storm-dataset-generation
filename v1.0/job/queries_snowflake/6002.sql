
WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        a.name AS actor_name,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND ci.nr_order < 3
    GROUP BY 
        t.title, t.production_year, ct.kind, a.name
)
SELECT 
    movie_title, 
    production_year, 
    company_type, 
    actor_name, 
    keyword_count
FROM 
    MovieData
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
