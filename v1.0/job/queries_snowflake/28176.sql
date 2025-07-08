
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        c.kind AS company_type,
        pi.info AS person_info
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id AND a.name IS NOT NULL
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
),
AggregatedInfo AS (
    SELECT 
        movie_id,
        title,
        production_year,
        LISTAGG(DISTINCT actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors,
        LISTAGG(DISTINCT keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords,
        LISTAGG(DISTINCT company_type, ', ') WITHIN GROUP (ORDER BY company_type) AS companies,
        LISTAGG(DISTINCT person_info, ', ') WITHIN GROUP (ORDER BY person_info) AS information
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    actors,
    keywords,
    companies,
    information
FROM 
    AggregatedInfo
ORDER BY 
    production_year DESC, title;
