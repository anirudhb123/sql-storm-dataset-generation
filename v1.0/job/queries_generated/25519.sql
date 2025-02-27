WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
CompanyNames AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    mk.keywords,
    cn.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN 
    CompanyNames cn ON cn.movie_id = rm.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
