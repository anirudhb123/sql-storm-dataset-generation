WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
ActorInfo AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mC.company_count, 0) AS company_count,
        COALESCE(mC.company_names, 'None') AS company_names,
        COALESCE(aI.actor_name, 'No actors listed') AS actor_name,
        COALESCE(aI.role_count, 0) AS role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanies mC ON rm.movie_id = mC.movie_id
    LEFT JOIN 
        ActorInfo aI ON rm.movie_id = aI.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.company_names,
    md.actor_name,
    md.role_count
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000 AND
    (md.company_count > 2 OR md.role_count > 5)
ORDER BY 
    md.production_year DESC, md.title;
