WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL 
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
ActorNames AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        ci.movie_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
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
NullCheck AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.actor_count,
        ARRAY_AGG(DISTINCT an.actor_name) AS actor_names,
        COALESCE(CM.company_name, 'No Production Company') AS production_company,
        COALESCE(CM.company_type, 'Unknown') AS company_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        ActorNames an ON tm.movie_id = an.movie_id
    LEFT JOIN 
        CompanyMovies CM ON tm.movie_id = CM.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.actor_count, CM.company_name, CM.company_type
)
SELECT 
    movie_id,
    title,
    actor_count,
    actor_names,
    production_company,
    company_type,
    CASE 
        WHEN actor_count = 0 THEN 'No Actors'
        WHEN production_company IS NULL THEN 'Null Production Company'
        ELSE 'Valid Entry'
    END AS validity_check
FROM 
    NullCheck
ORDER BY 
    actor_count DESC, title;
