
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM title m
    WHERE m.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cd.company_count, 0) AS company_count,
    CASE 
        WHEN COALESCE(ac.actor_count, 0) > 10 THEN 'Many Actors'
        WHEN COALESCE(ac.actor_count, 0) BETWEEN 5 AND 10 THEN 'Moderate Actors'
        ELSE 'Few Actors'
    END AS actor_density,
    cd.company_names
FROM RankedMovies rm
LEFT JOIN ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.rank <= 5
ORDER BY rm.production_year DESC, rm.title;
