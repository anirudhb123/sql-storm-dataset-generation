WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY t.id, t.title, t.production_year
),
ActorStats AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies
    FROM aka_name a
    JOIN cast_info ci ON ci.person_id = a.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
    GROUP BY a.name
),
CompanyStats AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies
    FROM company_name cn
    JOIN movie_companies mc ON mc.company_id = cn.id
    JOIN title mt ON mc.movie_id = mt.id
    GROUP BY cn.name
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.keyword_count,
    m.keywords,
    a.actor_name,
    a.movie_count AS actor_movie_count,
    a.movies AS actor_movies,
    c.company_name,
    c.movie_count AS company_movie_count,
    c.movies AS company_movies
FROM MovieInfo m
JOIN ActorStats a ON m.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name = a.actor_name))
JOIN CompanyStats c ON m.movie_id IN (SELECT movie_id FROM movie_companies WHERE company_id IN (SELECT id FROM company_name WHERE name = c.company_name))
WHERE m.production_year BETWEEN 2000 AND 2023
ORDER BY m.production_year DESC, m.keyword_count DESC, a.movie_count DESC, c.movie_count DESC;
