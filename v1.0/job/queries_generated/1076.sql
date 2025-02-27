WITH movie_summary AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        SUM(mci.note IS NOT NULL) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN movie_companies mci ON t.id = mci.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),
actor_info AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        COUNT(*) AS role_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.name, c.movie_id
),
top_movies AS (
    SELECT 
        ms.title_id,
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.keywords,
        ms.company_count
    FROM movie_summary ms
    WHERE ms.rank_by_cast <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ai.actor_name, 'No Actor') AS actor_name,
    COALESCE(ai.role_count, 0) AS role_count,
    tm.keywords,
    tm.company_count
FROM top_movies tm
LEFT JOIN actor_info ai ON tm.title_id = ai.movie_id
ORDER BY tm.production_year DESC, tm.actor_count DESC;
