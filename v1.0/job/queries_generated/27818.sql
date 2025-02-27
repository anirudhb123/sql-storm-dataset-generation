WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_title, 
        rm.production_year, 
        rm.total_cast, 
        rm.movie_keywords
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        COUNT(c.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.name
),
top_actors AS (
    SELECT 
        ad.actor_name,
        ad.movies_count,
        ad.movie_titles
    FROM 
        actor_details ad
    WHERE 
        ad.movies_count >= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.movie_keywords,
    ta.actor_name,
    ta.movies_count,
    ta.movie_titles
FROM 
    top_movies tm
LEFT JOIN 
    top_actors ta ON tm.total_cast = ta.movies_count 
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
