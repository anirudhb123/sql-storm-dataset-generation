
WITH RecentMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        a.name AS actor_name,
        ci.role_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2020
    GROUP BY 
        mt.id, mt.title, mt.production_year, a.name, ci.role_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.keywords,
    cd.company_names,
    cd.company_types
FROM 
    RecentMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
