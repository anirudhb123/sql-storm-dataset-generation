WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordStats AS (
    SELECT 
        UNNEST(keywords) AS keyword,
        COUNT(*) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        keyword
),
CompanyStats AS (
    SELECT 
        UNNEST(companies) AS company,
        COUNT(*) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        company
),
ActorStats AS (
    SELECT 
        UNNEST(actors) AS actor,
        COUNT(*) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor
)
SELECT 
    'Keywords' AS stat_type, 
    keyword, 
    movie_count 
FROM 
    KeywordStats
ORDER BY 
    movie_count DESC 
LIMIT 10

UNION ALL 

SELECT 
    'Companies' AS stat_type, 
    company, 
    movie_count 
FROM 
    CompanyStats
ORDER BY 
    movie_count DESC 
LIMIT 10

UNION ALL 

SELECT 
    'Actors' AS stat_type, 
    actor, 
    movie_count 
FROM 
    ActorStats
ORDER BY 
    movie_count DESC 
LIMIT 10;
