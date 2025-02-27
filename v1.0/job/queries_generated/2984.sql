WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
),
ActorRoles AS (
    SELECT 
        a.person_id,
        MIN(c.nr_order) AS first_role_order,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.person_id
),
FilteredActors AS (
    SELECT 
        ar.person_id,
        a.name,
        ar.first_role_order,
        ar.role_count
    FROM ActorRoles ar
    JOIN aka_name a ON ar.person_id = a.person_id
    WHERE ar.role_count > 2
),
MoviesWithRoles AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        fa.person_id,
        fa.name,
        fa.first_role_order
    FROM MovieDetails md
    JOIN cast_info ci ON md.title_id = ci.movie_id
    JOIN FilteredActors fa ON ci.person_id = fa.person_id
)
SELECT 
    m.title,
    m.production_year,
    fa.name AS actor_name,
    fa.first_role_order,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM MoviesWithRoles m
JOIN movie_keyword mk ON m.title_id = mk.movie_id
GROUP BY m.title, m.production_year, fa.name, fa.first_role_order
HAVING COUNT(DISTINCT mk.keyword) > 1
ORDER BY m.production_year DESC, m.title;
