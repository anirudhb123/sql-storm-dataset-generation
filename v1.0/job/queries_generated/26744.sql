WITH MovieInfo AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year BETWEEN 1980 AND 2023
    GROUP BY t.id, t.title, t.production_year, c.name
),

ActorStatistics AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        MAX(t.production_year) AS last_movie_year,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE a.name IS NOT NULL
    GROUP BY a.name
)

SELECT 
    mi.movie_title,
    mi.production_year,
    mi.company_name,
    mi.actors,
    mi.keywords,
    as.actor_name,
    as.movie_count,
    as.last_movie_year,
    as.movies
FROM MovieInfo mi
JOIN ActorStatistics as ON mi.actors LIKE '%' || as.actor_name || '%'
ORDER BY mi.production_year DESC, as.movie_count DESC
LIMIT 50;
