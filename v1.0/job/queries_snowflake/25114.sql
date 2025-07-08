
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT title, production_year, total_cast, actors, keywords
    FROM RankedMovies
    WHERE year_rank <= 5
)
SELECT 
    production_year,
    COUNT(*) AS movie_count,
    AVG(total_cast) AS avg_cast_size,
    LISTAGG(title, '; ') WITHIN GROUP (ORDER BY title) AS top_movies,
    LISTAGG(actors, '; ') WITHIN GROUP (ORDER BY actors) AS involved_actors,
    LISTAGG(keywords, '; ') WITHIN GROUP (ORDER BY keywords) AS associated_keywords
FROM 
    TopMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
