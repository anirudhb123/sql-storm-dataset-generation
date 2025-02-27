
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    ad.actors,
    ad.roles,
    CASE 
        WHEN md.production_year IS NOT NULL AND md.production_year BETWEEN 2000 AND 2020 THEN '21st Century'
        WHEN md.production_year IS NOT NULL AND md.production_year < 2000 THEN '20th Century'
        ELSE 'Unknown Year'
    END AS era
FROM 
    MovieDetails md
LEFT JOIN 
    ActorDetails ad ON md.movie_id = ad.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
