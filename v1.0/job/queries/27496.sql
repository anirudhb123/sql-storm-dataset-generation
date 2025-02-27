
WITH MovieTitleInfo AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        p.gender
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        name p ON an.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000
        AND LENGTH(k.keyword) > 5
),

AggregatedInfo AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT movie_keyword) AS keyword_count,
        COUNT(DISTINCT gender) AS gender_count,
        STRING_AGG(DISTINCT company_type, ', ') AS companies_involved
    FROM 
        MovieTitleInfo
    GROUP BY 
        movie_title, production_year
)

SELECT 
    movie_title,
    production_year,
    keyword_count,
    gender_count,
    companies_involved
FROM 
    AggregatedInfo
ORDER BY 
    production_year DESC, 
    keyword_count DESC, 
    gender_count ASC
FETCH FIRST 50 ROWS ONLY;
