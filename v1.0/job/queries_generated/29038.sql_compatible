
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
ActorDetails AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
)
SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.keywords,
    ad.actor_name,
    ad.movie_count
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    ActorDetails ad ON a.person_id = ad.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    ad.movie_count DESC
LIMIT 50;
