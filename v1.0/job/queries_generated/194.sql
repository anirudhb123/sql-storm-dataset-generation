WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.person_id
),
CompanyMovies AS (
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
InterestingKeywords AS (
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
    rm.title,
    rm.production_year,
    amc.movie_count,
    cm.company_name,
    cm.company_type,
    ik.keywords,
    COALESCE(amc.movie_count, 0) AS actor_movie_count,
    CASE 
        WHEN amc.movie_count IS NULL THEN 'No Movies'
        WHEN amc.movie_count > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovieCount amc ON rm.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = amc.person_id)
LEFT JOIN 
    CompanyMovies cm ON rm.title_id = cm.movie_id
LEFT JOIN 
    InterestingKeywords ik ON rm.title_id = ik.movie_id
WHERE 
    rm.movie_rank <= 10  -- Consider only top 10 movies per year
ORDER BY 
    rm.production_year DESC, 
    rm.title;
