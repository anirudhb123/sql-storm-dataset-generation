WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL
),
MovieWithKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        RankedMovies m ON mk.movie_id = m.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        cn.name AS actor_name,
        COUNT(ci.id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    WHERE 
        cn.name IS NOT NULL
),
CompanyUsage AS (
    SELECT 
        mc.movie_id,
        coc.name AS company_name,
        col.kind AS company_kind,
        CASE 
            WHEN mc.note IS NULL THEN 'No Note' 
            ELSE mc.note 
        END AS note
    FROM 
        movie_companies mc
    JOIN 
        company_name coc ON mc.company_id = coc.id
    JOIN 
        company_type col ON mc.company_type_id = col.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mwk.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.actor_name, 'No Cast') AS actor_name,
    cd.actor_count,
    cusage.company_name,
    cusage.company_kind,
    cusage.note
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieWithKeywords mwk ON rm.movie_id = mwk.movie_id
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyUsage cusage ON rm.movie_id = cusage.movie_id
WHERE 
    (rm.year_rank = 1 OR cd.actor_count > 1)
    AND (cusage.company_name IS NOT NULL OR cusage.company_name IS NULL)
ORDER BY 
    rm.production_year DESC, 
    mwk.keywords DESC NULLS FIRST, 
    cd.actor_count DESC;
