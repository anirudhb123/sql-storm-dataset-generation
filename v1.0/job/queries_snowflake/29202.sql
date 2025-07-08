
WITH MovieActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.gender,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        p.gender = 'M' 
        AND t.production_year BETWEEN 2000 AND 2023
),

KeywordedMovies AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS all_keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    ma.movie_id,
    ma.movie_title,
    ma.production_year,
    ma.actor_name,
    ma.actor_rank,
    km.all_keywords
FROM 
    MovieActors ma
LEFT JOIN 
    KeywordedMovies km ON ma.movie_id = km.movie_id
ORDER BY 
    ma.production_year DESC, 
    ma.movie_title, 
    ma.actor_rank;
