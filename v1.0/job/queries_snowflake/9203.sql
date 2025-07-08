
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM ranked_movies rm
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    p.name AS main_actor,
    LISTAGG(DISTINCT kw.keyword, ',') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM top_movies tm
JOIN cast_info ci ON tm.movie_id = ci.movie_id
JOIN aka_name a ON ci.person_id = a.person_id
JOIN name p ON a.person_id = p.imdb_id
LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE tm.rank <= 10
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.cast_count, p.name
ORDER BY tm.cast_count DESC;
