WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        p.info AS director_info
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        person_info p ON ci.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
    WHERE 
        t.production_year >= 2000
    AND 
        k.keyword LIKE 'Action%'
),
AggregateData AS (
    SELECT 
        movie_id,
        title,
        production_year,
        COUNT(DISTINCT keyword) AS total_keywords,
        STRING_AGG(DISTINCT company_type, ', ') AS companies
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_keywords,
    md.companies
FROM 
    AggregateData md
ORDER BY 
    md.production_year DESC, 
    md.total_keywords DESC
LIMIT 100;
