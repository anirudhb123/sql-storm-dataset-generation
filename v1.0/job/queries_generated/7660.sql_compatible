
WITH ActorRoles AS (
    SELECT a.id AS actor_id, a.name AS actor_name, r.role AS role_name, c.movie_id
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
),
MoviesWithInfo AS (
    SELECT t.id AS movie_id, t.title, t.production_year, m.info
    FROM title t
    JOIN movie_info m ON t.id = m.movie_id
    WHERE m.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
),
KeywordInfo AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    aw.actor_name,
    mw.title,
    mw.production_year,
    mw.info AS movie_summary,
    ki.keywords
FROM ActorRoles aw
JOIN complete_cast cc ON aw.movie_id = cc.movie_id
JOIN MoviesWithInfo mw ON cc.movie_id = mw.movie_id
LEFT JOIN KeywordInfo ki ON mw.movie_id = ki.movie_id
WHERE aw.role_name = 'Actor'
ORDER BY mw.production_year DESC, aw.actor_name;
