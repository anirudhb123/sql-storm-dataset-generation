WITH ActorMovieInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id 
    GROUP BY a.id, a.name, t.title, t.production_year, ct.kind
)
SELECT 
    actor_id,
    actor_name,
    movie_title,
    movie_year,
    company_type,
    keywords,
    num_companies
FROM ActorMovieInfo
WHERE movie_year > 2000
ORDER BY movie_year DESC, actor_name ASC;

