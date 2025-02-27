WITH MovieInfo AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        a.name AS actor_name,
        c.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword IS NOT NULL
),

UniqueMovieInfo AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_type, ', ') AS companies
    FROM 
        MovieInfo
    GROUP BY 
        title, production_year
)

SELECT 
    title,
    production_year,
    keywords,
    actors,
    companies
FROM 
    UniqueMovieInfo
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, title;
