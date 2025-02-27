WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role,
        COUNT(c.id) AS movie_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.person_id, r.role
),
TopActors AS (
    SELECT 
        ar.person_id,
        ar.role,
        ar.movie_count,
        RANK() OVER (PARTITION BY ar.role ORDER BY ar.movie_count DESC) AS role_rank
    FROM ActorRoles ar
)
SELECT 
    a.name,
    tt.title,
    tt.production_year,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    tt.title_rank,
    ta.role,
    ta.movie_count
FROM RankedTitles tt
LEFT JOIN movie_companies mc ON mc.movie_id = tt.title_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
JOIN TopActors ta ON ta.movie_count > 5
JOIN aka_name a ON a.person_id = ta.person_id
WHERE tt.title_rank <= 5
  AND tt.production_year >= 2000
ORDER BY tt.production_year DESC, tt.title;
