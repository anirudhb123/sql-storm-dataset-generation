WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        at.kind_id,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM aka_title at
),
FilteredTitles AS (
    SELECT 
        rt.title, 
        rt.production_year,
        kt.kind 
    FROM RankedTitles rt
    JOIN kind_type kt ON rt.kind_id = kt.id
    WHERE rt.year_rank <= 10
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        ci.note AS role_note,
        COUNT(*) OVER (PARTITION BY ak.person_id) AS total_roles
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    WHERE ak.name IS NOT NULL
),
TitleRoleCounts AS (
    SELECT 
        ft.title,
        COUNT(DISTINCT ar.actor_name) AS total_actors
    FROM FilteredTitles ft
    LEFT JOIN ActorRoles ar ON ft.title = ar.movie_title
    GROUP BY ft.title
    HAVING COUNT(DISTINCT ar.actor_name) > 5
)
SELECT 
    tr.title,
    tr.production_year,
    tr.kind,
    COALESCE(arc.total_actors, 0) AS actor_count,
    CASE 
        WHEN TRIM(TRAILING 's' FROM tr.title) = TRIM(TRAILING 's' FROM 'The Matrix') THEN 'A classic sci-fi'
        ELSE 'Other'
    END AS title_description
FROM FilteredTitles tr
LEFT JOIN TitleRoleCounts arc ON tr.title = arc.title
WHERE tr.production_year BETWEEN 1990 AND 2022
ORDER BY tr.production_year ASC, actor_count DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;