WITH MovieData AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000 AND
        ak.name IS NOT NULL
),
AggregatedData AS (
    SELECT 
        md.movie_id,
        COUNT(DISTINCT md.actor_name) AS actor_count,
        COUNT(DISTINCT md.company_type) AS companies_count,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
    FROM 
        MovieData md
    GROUP BY 
        md.movie_id
)
SELECT 
    t.title,
    ad.actor_count,
    ad.companies_count,
    ad.keywords
FROM 
    AggregatedData ad
JOIN 
    aka_title t ON ad.movie_id = t.id
ORDER BY 
    ad.actor_count DESC,
    ad.companies_count DESC,
    t.title;
