WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    mk.keywords,
    mci.companies,
    mci.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON mci.movie_id = rm.movie_id
WHERE 
    rm.actor_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
