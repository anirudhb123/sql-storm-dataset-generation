
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM title t
    WHERE t.production_year >= 2000
), ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
), CompDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    cd.companies
FROM RankedTitles rt
LEFT JOIN ActorCount ac ON rt.title_id = ac.movie_id
LEFT JOIN CompDetails cd ON rt.title_id = cd.movie_id
WHERE rt.rank <= 5
ORDER BY rt.production_year DESC, rt.title;
