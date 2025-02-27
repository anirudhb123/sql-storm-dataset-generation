WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(ci.nr_order) AS avg_order
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        cn.country_code = 'USA'
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        avg_order,
        RANK() OVER (ORDER BY actor_count DESC, avg_order ASC) AS rank
    FROM 
        ranked_movies
    WHERE 
        actor_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.avg_order
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
