
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year
),

top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM ranked_movies 
    WHERE rank <= 10
)

SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    r.role AS actor_role,
    cn.name AS company_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM top_movies tm
JOIN cast_info ci ON tm.movie_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN role_type r ON ci.role_id = r.id
JOIN movie_companies mc ON tm.movie_id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY tm.movie_id, tm.title, tm.production_year, ak.name, r.role, cn.name
ORDER BY tm.production_year DESC, tm.title;
