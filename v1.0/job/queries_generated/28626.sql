WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year AS year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.movie_title,
        rt.year,
        kt.kind AS kind
    FROM RankedTitles rt
    JOIN kind_type kt ON rt.kind_id = kt.id
    WHERE rt.rank <= 5
),
ActorAndRoles AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        c.person_role_id,
        r.role AS role_name
    FROM cast_info c
    JOIN aka_name ak ON ak.person_id = c.person_id
    JOIN role_type r ON r.id = c.person_role_id
),
TitleWithActors AS (
    SELECT 
        tt.movie_title,
        tt.year,
        tt.kind,
        ar.actor_name,
        COUNT(ar.role_name) AS role_count
    FROM TopTitles tt
    LEFT JOIN ActorAndRoles ar ON ar.movie_id IN (
        SELECT mt.id FROM movie_info mt JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
        WHERE mk.keyword_id IN (SELECT id FROM keyword WHERE keyword ILIKE '%action%') -- Focusing on action keywords
    )
    GROUP BY tt.movie_title, tt.year, tt.kind, ar.actor_name
),
FinalResults AS (
    SELECT 
        twa.movie_title,
        twa.year,
        twa.kind,
        twa.actor_name,
        twa.role_count,
        CASE WHEN twa.role_count > 0 THEN 'Has Roles' ELSE 'No Roles' END AS role_status
    FROM TitleWithActors twa
    ORDER BY twa.kind, twa.year DESC, twa.role_count DESC
)
SELECT 
    DISTINCT movie_title,
    year,
    kind,
    actor_name,
    role_count,
    role_status
FROM FinalResults
WHERE role_status = 'Has Roles'
LIMIT 10;
