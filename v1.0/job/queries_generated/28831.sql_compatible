
WITH movie_actors AS (
    SELECT 
        a.name AS actor_name, 
        a.person_id, 
        c.movie_id, 
        t.title AS movie_title, 
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.name IS NOT NULL AND 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.name, a.person_id, c.movie_id, t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    ma.actor_name, 
    ma.movie_title, 
    ma.production_year,
    STRING_AGG(DISTINCT CONCAT(cd.company_name, ' (', cd.company_type, ')'), '; ') AS companies,
    ma.keywords
FROM 
    movie_actors ma
LEFT JOIN 
    company_details cd ON ma.movie_id = cd.movie_id
GROUP BY 
    ma.actor_name, ma.movie_title, ma.production_year, ma.keywords
ORDER BY 
    ma.production_year DESC, 
    ma.actor_name;
