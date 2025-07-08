
WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL AND 
        at.production_year >= 2000
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
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
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
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords,
    COALESCE(cd.companies, 'No companies') AS production_companies,
    COALESCE(cd.company_types, 'No company types') AS production_types,
    CASE 
        WHEN rm.production_year IS NOT NULL 
        THEN 'Year: ' || CAST(rm.production_year AS STRING) || ', Title: ' || rm.title
        ELSE 'Untitled Movie'
    END AS title_year_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, 
    total_actors DESC NULLS LAST;
