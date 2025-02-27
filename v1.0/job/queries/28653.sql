WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title AS title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    AND 
        (LOWER(a.name) LIKE '%john%' OR LOWER(t.title) LIKE '%adventure%')
),
ActorCounts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        MovieData
    GROUP BY 
        movie_id
),
DistinctKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieData
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ac.actor_count,
    dk.keywords,
    STRING_AGG(DISTINCT md.company_type, ', ') AS company_types
FROM 
    MovieData md
JOIN 
    ActorCounts ac ON md.movie_id = ac.movie_id
JOIN 
    DistinctKeywords dk ON md.movie_id = dk.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, ac.actor_count, dk.keywords
ORDER BY 
    md.production_year DESC, ac.actor_count DESC;
