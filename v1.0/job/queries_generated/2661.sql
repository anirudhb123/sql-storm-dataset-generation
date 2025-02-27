WITH RankedMovies AS (
    SELECT t.id AS movie_id, t.title, t.production_year, 
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS actor_rank
    FROM aka_title t
    JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT a.id AS actor_id, a.name, a.person_id, 
           COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS roles_played
    FROM aka_name a
    LEFT JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.id, a.name, a.person_id
),
TopActors AS (
    SELECT actor_id, name, roles_played
    FROM ActorDetails
    WHERE roles_played > 0
),
MovieInfo AS (
    SELECT m.movie_id, 
           STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
           STRING_AGG(DISTINCT pi.info, '; ') AS additional_info
    FROM movie_keyword mk
    JOIN movie_info mi ON mk.movie_id = mi.movie_id
    JOIN RankedMovies m ON m.movie_id = mk.movie_id
    LEFT JOIN person_info pi ON pi.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = m.movie_id)
    GROUP BY m.movie_id
)

SELECT r.movie_id, r.title, r.production_year, 
       ta.name AS top_actor, ta.roles_played, 
       mi.keywords, mi.additional_info
FROM RankedMovies r
JOIN TopActors ta ON r.actor_rank = 1
LEFT JOIN MovieInfo mi ON r.movie_id = mi.movie_id
WHERE r.production_year >= 2000
ORDER BY r.production_year DESC, r.title ASC;
