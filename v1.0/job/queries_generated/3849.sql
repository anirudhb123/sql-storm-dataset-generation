WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        ct.kind AS role_type
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type ct ON c.role_id = ct.id
)
SELECT 
    t.title,
    t.production_year,
    a.name AS actor_name,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT m.id) AS movie_count,
    MAX(k.keyword) AS popular_keyword
FROM RankedTitles t
LEFT JOIN ActorInfo a ON t.title_id = a.movie_id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE t.rank = 1
AND (a.actor_id IS NOT NULL OR mc.id IS NOT NULL)
GROUP BY t.title, t.production_year, a.name, ct.kind
ORDER BY t.production_year DESC, t.title;
