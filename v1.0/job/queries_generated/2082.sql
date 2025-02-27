WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_num
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), relevant_cast AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year,
        c.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
    WHERE 
        a.name IS NOT NULL
), movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_cast,
    rk.actor_name,
    mk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    relevant_cast rk ON rm.title = rk.title AND rm.production_year = rk.production_year
LEFT JOIN 
    movie_keywords mk ON rm.title = (SELECT title FROM aka_title WHERE id = rm.id)
WHERE 
    rm.rank_num <= 5
ORDER BY 
    rm.production_year DESC, rm.num_cast DESC, rk.nr_order;
