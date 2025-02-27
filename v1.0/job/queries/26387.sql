WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        ak.name AS actor_name,
        pi.info AS person_info
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        t.production_year > 2000
        AND k.keyword LIKE '%action%'
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    COUNT(DISTINCT person_info) AS info_count
FROM 
    MovieDetails
GROUP BY 
    movie_title, 
    production_year
ORDER BY 
    production_year DESC, 
    movie_title;
