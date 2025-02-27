WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM
        aka_title mt
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
MoviesWithActorRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        ar.role_count,
        COALESCE(NULLIF(LOWER(ar.role_name), 'main'), 'supporting') AS role_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
),
KeywordInfo AS (
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
FinalResult AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.production_year,
        mw.actor_name,
        mw.role_name,
        mw.role_count,
        mw.role_category,
        ki.keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        MoviesWithActorRoles mw
    LEFT JOIN 
        movie_companies mc ON mw.movie_id = mc.movie_id
    LEFT JOIN 
        KeywordInfo ki ON mw.movie_id = ki.movie_id
    GROUP BY 
        mw.movie_id, mw.title, mw.production_year, mw.actor_name, mw.role_name, mw.role_count, mw.role_category, ki.keywords
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.role_name,
    fr.role_count,
    fr.role_category,
    COALESCE(fr.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN fr.production_companies > 1 THEN 'Multiple Companies'
        WHEN fr.production_companies = 1 THEN 'Single Company'
        ELSE 'No Companies'
    END AS company_status
FROM 
    FinalResult fr
WHERE 
    fr.production_year IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.title ASC;
