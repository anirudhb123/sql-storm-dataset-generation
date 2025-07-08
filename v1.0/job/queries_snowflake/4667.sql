
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), CastDetails AS (
    SELECT 
        c.movie_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
), MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.role_name,
        mcd.company_count,
        mcd.companies,
        COUNT(cd.actor_name) OVER (PARTITION BY rm.movie_id) AS total_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.role_name,
    fr.company_count,
    fr.companies,
    fr.total_actors
FROM 
    FinalResults fr
WHERE 
    fr.production_year >= 2000
    AND fr.total_actors > 0
ORDER BY 
    fr.production_year DESC, 
    fr.title ASC;
