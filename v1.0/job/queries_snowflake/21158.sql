WITH RecursiveActors AS (
    SELECT ka.id AS actor_id, ka.name AS actor_name, c.movie_id, 
           ROW_NUMBER() OVER (PARTITION BY ka.id ORDER BY ka.name) AS actor_rank
    FROM aka_name AS ka
    JOIN cast_info AS c ON ka.person_id = c.person_id
),
MovieDetails AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           ct.kind AS comp_kind, 
           COALESCE(SUM(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE NULL END), 0) AS num_companies,
           MAX(mi.info) AS movie_info
    FROM aka_title AS m
    LEFT JOIN movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info AS mi ON m.id = mi.movie_id
    GROUP BY m.id, m.title, m.production_year, ct.kind
),
RankedMovies AS (
    SELECT *, 
           RANK() OVER (ORDER BY production_year DESC, title) AS year_rank
    FROM MovieDetails
    WHERE production_year IS NOT NULL
),
ActorMovieStats AS (
    SELECT a.actor_id, a.actor_name, rm.title, rm.movie_id, 
           rm.production_year, rm.num_companies,
           CASE 
               WHEN rm.num_companies > 2 THEN 'Highly Collaborated'
               WHEN rm.num_companies = 0 THEN 'No Collaborations'
               ELSE 'Standard'
           END AS collaboration_rating,
           COALESCE(am.movie_id, -1) AS related_movie_id
    FROM RecursiveActors AS a
    JOIN RankedMovies AS rm ON a.movie_id = rm.movie_id
    LEFT JOIN movie_link AS am ON rm.movie_id = am.movie_id
    WHERE a.actor_rank <= 5
)
SELECT a.actor_name, a.title, a.production_year, 
       a.num_companies, a.collaboration_rating, 
       CASE 
           WHEN a.related_movie_id = -1 THEN 'No linked movies'
           ELSE 'Linked movie exists'
       END AS linked_movie_status
FROM ActorMovieStats AS a
WHERE a.collaboration_rating != 'No Collaborations'
ORDER BY a.production_year DESC, a.actor_name ASC;