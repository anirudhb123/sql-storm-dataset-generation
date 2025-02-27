
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title m
    JOIN movie_info mi ON m.id = mi.movie_id
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON m.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year BETWEEN 1990 AND 2023
    GROUP BY m.id, m.title, m.production_year
    HAVING COUNT(DISTINCT k.id) > 5
    ORDER BY m.production_year DESC
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_names,
        rm.actor_count,
        ROW_NUMBER() OVER (ORDER BY rm.actor_count DESC) AS rank
    FROM ranked_movies rm
    WHERE rm.actor_count > 3
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    mi.info AS movie_info,
    ct.kind AS company_type
FROM top_movies tm
LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_info mi ON tm.movie_id = mi.movie_id
WHERE ct.kind IS NOT NULL
ORDER BY tm.actor_count DESC, tm.production_year DESC
LIMIT 10;
