
WITH RankedTitles AS (
    SELECT 
        a.name AS alias_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        t.movie_id
    FROM aka_name a
    JOIN aka_title t ON a.person_id = t.movie_id
),
FilteredActors AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS actor_role,
        COUNT(*) AS movie_count
    FROM cast_info c
    JOIN role_type r ON c.person_role_id = r.id
    WHERE r.role LIKE '%Actor%'
    GROUP BY c.person_id, c.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rt.alias_name,
    rt.movie_title,
    rt.production_year,
    fa.actor_role,
    fa.movie_count,
    mk.keywords
FROM RankedTitles rt
JOIN FilteredActors fa ON rt.movie_id = fa.movie_id
LEFT JOIN MovieKeywords mk ON rt.movie_id = mk.movie_id
WHERE rt.title_rank <= 5
ORDER BY rt.production_year DESC, rt.movie_title ASC;
