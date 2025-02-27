WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        k.keyword AS keyword,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ARRAY_AGG(DISTINCT p.info) AS person_info
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        mt.production_year >= 2000 AND
        k.keyword IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year, k.keyword
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(keyword) AS keyword_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(actors) AS actor_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    k.keyword_count,
    a.actor_count,
    md.company_names,
    md.actors,
    md.person_info
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount k ON md.movie_id = k.movie_id
LEFT JOIN 
    ActorCount a ON md.movie_id = a.movie_id
ORDER BY 
    md.production_year DESC, 
    k.keyword_count DESC,
    a.actor_count DESC;
