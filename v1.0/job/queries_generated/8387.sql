WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER(PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
    AND 
        ak.name IS NOT NULL
),
MovieKeywordAggregation AS (
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
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    GROUP_CONCAT(DISTINCT rm.actor_name ORDER BY rm.actor_rank) AS all_actors,
    mka.keywords,
    mcd.companies
FROM 
    RankedMovies rm
JOIN 
    MovieKeywordAggregation mka ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mka.movie_id LIMIT 1)
JOIN 
    MovieCompanyDetails mcd ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mcd.movie_id LIMIT 1)
GROUP BY 
    rm.movie_title,
    rm.production_year,
    mka.keywords,
    mcd.companies
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
