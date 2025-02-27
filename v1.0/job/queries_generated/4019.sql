WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) as rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        MIN(CASE WHEN mc.note IS NULL THEN 'No Note' ELSE mc.note END) AS note_info
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, co.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    mc.company_name,
    mc.company_type,
    mc.note_info
FROM RankedMovies rm
LEFT JOIN ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE rm.rank <= 5
ORDER BY rm.production_year DESC, ac.actor_count DESC NULLS LAST, rm.title;
