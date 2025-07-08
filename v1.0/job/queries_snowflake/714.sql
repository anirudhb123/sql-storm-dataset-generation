
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActedMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
RelevantMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        am.actor_count,
        ARRAY_AGG(DISTINCT cm.company_name) AS production_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActedMovies am ON rm.movie_id = am.movie_id
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, am.actor_count
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.actor_count, 0) AS actor_count,
    COALESCE(rm.production_companies, ARRAY_CONSTRUCT()) AS production_companies
FROM 
    RelevantMovies rm
ORDER BY 
    rm.production_year DESC, 
    rm.title;
