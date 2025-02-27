
WITH ranked_movies AS (
    SELECT t.id AS movie_id, t.title, t.production_year, COUNT(ci.person_id) AS cast_count
    FROM aka_title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
    HAVING COUNT(ci.person_id) > 5
),
movie_keywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_companies AS (
    SELECT mc.movie_id, STRING_AGG(cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT rm.title, rm.production_year, rm.cast_count, mk.keywords, mc.company_names
FROM ranked_movies rm
LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN movie_companies mc ON rm.movie_id = mc.movie_id
ORDER BY rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
