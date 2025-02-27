WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
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
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    mk.keywords,
    mci.company_names,
    mci.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
