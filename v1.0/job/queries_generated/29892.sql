WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank_by_company
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name m ON mc.company_id = m.id
    GROUP BY t.id, t.title, t.production_year
),
popular_people AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(c.movie_id) DESC) AS actor_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.person_id, a.name
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.company_count,
    pp.actor_name,
    pp.movie_count AS actor_movies,
    km.keyword_count
FROM ranked_movies rm
LEFT JOIN popular_people pp ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = pp.person_id)
LEFT JOIN keyword_movies km ON rm.movie_id = km.movie_id
WHERE rm.rank_by_company <= 3
ORDER BY rm.production_year DESC, rm.company_count DESC, pp.movie_count DESC;
