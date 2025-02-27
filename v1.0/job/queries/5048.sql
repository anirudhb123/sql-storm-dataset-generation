WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        ct.kind AS company_type,
        p.info AS person_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
),
AggregatedDetails AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    keywords,
    production_companies
FROM 
    AggregatedDetails
ORDER BY 
    production_year DESC, actor_count DESC;
