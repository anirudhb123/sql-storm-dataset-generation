WITH MovieTitles AS (
    SELECT t.id AS movie_id, t.title, t.production_year, kt.kind AS kind
    FROM aka_title t
    JOIN kind_type kt ON t.kind_id = kt.id
),
ActorRoles AS (
    SELECT ci.movie_id, a.name AS actor_name, r.role AS role
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
),
MovieKeywords AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
CompleteMovieInfo AS (
    SELECT mt.movie_id, mt.title, mt.production_year, mt.kind, ar.actor_name, ar.role, mk.keyword
    FROM MovieTitles mt
    LEFT JOIN ActorRoles ar ON mt.movie_id = ar.movie_id
    LEFT JOIN MovieKeywords mk ON mt.movie_id = mk.movie_id
)
SELECT cm.movie_id, cm.title, cm.production_year, cm.kind,
       STRING_AGG(DISTINCT cm.actor_name || ' (' || cm.role || ')', ', ') AS actors,
       STRING_AGG(DISTINCT cm.keyword, ', ') AS keywords
FROM CompleteMovieInfo cm
GROUP BY cm.movie_id, cm.title, cm.production_year, cm.kind
ORDER BY cm.production_year DESC, cm.title;
