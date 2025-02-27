WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS co_stars
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
top_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.actor_count,
    tm.co_stars
FROM 
    top_movies tm
WHERE 
    tm.rank <= 3
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;