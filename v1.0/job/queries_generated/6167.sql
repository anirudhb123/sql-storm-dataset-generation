WITH GenreCounts AS (
    SELECT kt.kind, COUNT(mt.movie_id) AS movie_count
    FROM kind_type kt
    LEFT JOIN aka_title mt ON kt.id = mt.kind_id
    GROUP BY kt.kind
),
CompanyCounts AS (
    SELECT co.name AS company_name, cc.kind_id, COUNT(mc.movie_id) AS produced_movies
    FROM company_name co
    JOIN movie_companies mc ON co.id = mc.company_id
    JOIN company_type cc ON mc.company_type_id = cc.id
    GROUP BY co.name, cc.kind_id
),
TopActors AS (
    SELECT ak.name AS actor_name, COUNT(ci.movie_id) AS total_movies
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    GROUP BY ak.name
    ORDER BY total_movies DESC
    LIMIT 10
)
SELECT 
    g.kind,
    g.movie_count,
    c.company_name,
    c.produced_movies,
    a.actor_name,
    a.total_movies
FROM GenreCounts g
JOIN CompanyCounts c ON g.movie_count > c.produced_movies
JOIN TopActors a ON a.total_movies >= 5
ORDER BY g.movie_count DESC, c.produced_movies DESC;
