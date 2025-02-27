WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        mc.company_id, 
        c.name AS company_name, 
        k.keyword, 
        a.name AS actor_name,
        a.id AS actor_id,
        t.production_year
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
AggregatedData AS (
    SELECT 
        movie_id, 
        title, 
        COUNT(DISTINCT company_name) AS company_count,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        RecursiveMovieCTE
    GROUP BY 
        movie_id, title
)
SELECT 
    ad.movie_id, 
    ad.title, 
    ad.company_count, 
    ad.actor_count, 
    ad.keywords
FROM 
    AggregatedData ad
WHERE 
    ad.actor_count > 5
ORDER BY 
    ad.actor_count DESC, 
    ad.company_count ASC;
