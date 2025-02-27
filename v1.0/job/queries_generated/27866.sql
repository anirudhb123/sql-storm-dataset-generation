WITH RecursiveMovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT comp.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT UNNEST(cast_names)) AS actor_count
    FROM 
        RecursiveMovieData
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    md.companies,
    ac.actor_count
FROM 
    RecursiveMovieData md
JOIN 
    ActorCount ac ON md.movie_id = ac.movie_id
ORDER BY 
    md.production_year DESC, 
    ac.actor_count DESC
LIMIT 10;
