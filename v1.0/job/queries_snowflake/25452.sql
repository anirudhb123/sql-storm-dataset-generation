WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT m.id) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies m ON a.id = m.movie_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
top_keywords AS (
    SELECT 
        movie_title, 
        production_year, 
        movie_keyword, 
        total_companies 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
actor_count AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.production_year
)
SELECT 
    tkw.movie_title,
    tkw.production_year,
    tkw.movie_keyword,
    tkw.total_companies,
    ac.actor_count
FROM 
    top_keywords tkw
JOIN 
    actor_count ac ON tkw.production_year = ac.production_year
ORDER BY 
    tkw.production_year, tkw.total_companies DESC;
