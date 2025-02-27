WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
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
CompanyInfo AS (
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
    WHERE 
        c.country_code IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    ac.actor_count,
    ci.company_name,
    ci.company_type,
    tk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
WHERE 
    ac.actor_count IS NOT NULL
    OR ci.company_name IS NOT NULL
    OR tk.keywords IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank;
