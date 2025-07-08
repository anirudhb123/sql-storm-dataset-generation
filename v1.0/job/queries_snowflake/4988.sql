
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank_within_year
    FROM title m
    WHERE m.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    cd.company_names,
    cd.total_companies,
    CASE 
        WHEN ac.actor_count > 10 THEN 'Ensemble Cast'
        WHEN ac.actor_count IS NULL THEN 'No Cast Info'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(m.rank_within_year, 0) AS production_rank
FROM RankedMovies m
LEFT JOIN ActorCounts ac ON m.movie_id = ac.movie_id
LEFT JOIN CompanyDetails cd ON m.movie_id = cd.movie_id
WHERE m.production_year >= (SELECT MAX(production_year) - 10 FROM title)
GROUP BY 
    m.movie_id,
    m.movie_title,
    m.production_year,
    ac.actor_count,
    cd.company_names,
    cd.total_companies,
    m.rank_within_year
ORDER BY m.production_year DESC, ac.actor_count DESC
LIMIT 50;
