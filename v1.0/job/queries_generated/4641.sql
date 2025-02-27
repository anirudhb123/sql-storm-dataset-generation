WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
        AND m.production_year >= 2000
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
        STRING_AGG(k.keyword, ', ') AS keywords
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
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        mk.keywords,
        COALESCE(cd.company_name, 'Independent') AS company_name,
        COALESCE(cd.company_type, 'N/A') AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    sm.title,
    sm.production_year,
    sm.actor_count,
    sm.keywords,
    sm.company_name,
    sm.company_type
FROM 
    SelectedMovies sm
ORDER BY 
    sm.production_year DESC, sm.actor_count DESC;
