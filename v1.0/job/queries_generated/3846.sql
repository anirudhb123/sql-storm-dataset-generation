WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        k.keyword AS keyword, 
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
),
ActorStats AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS movie_count, 
        AVG(CASE WHEN t.production_year IS NOT NULL THEN t.production_year ELSE NULL END) AS avg_movie_year
    FROM aka_name a
    INNER JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN title t ON ci.movie_id = t.id
    WHERE a.name IS NOT NULL
    GROUP BY a.name
),
TopMovies AS (
    SELECT 
        md.movie_title, 
        md.production_year, 
        COUNT(Q.actor_name) AS actor_count
    FROM MovieDetails md
    LEFT JOIN 
    (
        SELECT 
            ci.movie_id, 
            a.name AS actor_name
        FROM cast_info ci
        INNER JOIN aka_name a ON ci.person_id = a.person_id
    ) Q ON md.movie_id = Q.movie_id
    GROUP BY md.movie_title, md.production_year
    HAVING COUNT(Q.actor_name) > 3
)
SELECT 
    T.movie_title, 
    T.production_year, 
    A.actor_name, 
    A.movie_count, 
    A.avg_movie_year,
    CASE 
        WHEN T.actor_count > 5 THEN 'Blockbuster'
        WHEN T.actor_count BETWEEN 3 AND 5 THEN 'Moderate Hit'
        ELSE 'Flop'
    END AS box_office_status
FROM TopMovies T
JOIN ActorStats A ON T.movie_title = A.actor_name
ORDER BY T.production_year DESC, T.movie_title ASC;
