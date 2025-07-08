WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN cast_info c ON t.id = c.movie_id
    WHERE cn.country_code = 'USA'
    GROUP BY t.id, t.title, t.production_year
),
character_count AS (
    SELECT 
        t.id AS movie_id,
        SUM(LENGTH(t.title) - LENGTH(REPLACE(t.title, ' ', ''))) + 1 AS word_count,
        MIN(LENGTH(t.title)) AS min_length,
        MAX(LENGTH(t.title)) AS max_length
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.word_count,
        cc.min_length,
        cc.max_length
    FROM ranked_movies rm
    JOIN character_count cc ON rm.movie_id = cc.movie_id
    WHERE rm.movie_rank <= 5
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.word_count,
    tm.min_length,
    tm.max_length,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id) AS actor_count
FROM top_movies tm
ORDER BY tm.production_year DESC, actor_count DESC;
