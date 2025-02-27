WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank_per_kind
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
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
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    cd.company_name,
    cd.company_type,
    mk.keywords,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'Unknown'
        WHEN ac.actor_count > 5 THEN 'Blockbuster'
        ELSE 'Indie Film'
    END AS film_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
FULL OUTER JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE 
    (rm.rank_per_kind <= 5 OR cd.company_name IS NOT NULL)
    AND COALESCE(mk.keywords, '') != ''
ORDER BY 
    rm.production_year DESC,
    film_category DESC NULLS LAST;