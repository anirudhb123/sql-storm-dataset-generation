WITH ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        CONCAT(a.name, ' - ', t.title) AS highlight
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        a.name IS NOT NULL 
        AND t.production_year >= 2000 
        AND (k.keyword ILIKE '%action%' OR k.keyword ILIKE '%drama%')
),
AggregatedResults AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        ARRAY_AGG(DISTINCT production_year) AS production_years,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT highlight, '; ') AS highlights
    FROM 
        ActorTitles
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    movie_count,
    production_years,
    keywords,
    highlights
FROM 
    AggregatedResults
ORDER BY 
    movie_count DESC
LIMIT 10;

