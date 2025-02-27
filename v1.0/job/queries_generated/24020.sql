WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.movie_id, mt.linked_movie_id, 1 AS level
    FROM movie_link mt
    WHERE mt.link_type_id IN (SELECT id FROM link_type WHERE link = 'related')
    UNION ALL
    SELECT mt.movie_id, mt.linked_movie_id, mh.level + 1
    FROM movie_link mt
    JOIN MovieHierarchy mh ON mh.linked_movie_id = mt.movie_id
),
ActorMovies AS (
    SELECT a.person_id, m.title, m.production_year, COUNT(DISTINCT c.note) AS roles_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title m ON c.movie_id = m.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY a.person_id, m.title, m.production_year
),
TopActors AS (
    SELECT person_id, COUNT(DISTINCT title) AS total_movies
    FROM ActorMovies
    GROUP BY person_id
    HAVING COUNT(DISTINCT title) > 5
),
MovieInfo AS (
    SELECT m.movie_id, ARRAY_AGG(DISTINCT k.keyword) AS keywords, 
           MAX(mi.info) AS movie_info
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.movie_id
)
SELECT 
    a.name AS actor_name,
    ta.total_movies,
    mh.linked_movie_id AS related_movie_id,
    mi.keywords,
    mi.movie_info,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY ta.total_movies DESC) AS actor_rank,
    CASE 
        WHEN COUNT(DISTINCT c.id) = 0 THEN 'No Roles'
        ELSE 'Roles Exist'
    END AS role_status
FROM TopActors ta
JOIN aka_name a ON a.person_id = ta.person_id
JOIN MovieHierarchy mh ON mh.movie_id IN (
    SELECT movie_id 
    FROM movie_info_idx 
    WHERE info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
)
LEFT JOIN ActorMovies am ON am.person_id = a.person_id
LEFT JOIN MovieInfo mi ON am.title = mi.movie_info
LEFT JOIN cast_info c ON c.person_id = a.person_id
GROUP BY a.name, ta.total_movies, mh.linked_movie_id, mi.keywords, mi.movie_info
ORDER BY ta.total_movies DESC, actor_rank;
