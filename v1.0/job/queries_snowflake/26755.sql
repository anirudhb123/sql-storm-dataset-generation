
WITH movie_rankings AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        k.keyword AS genre
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),

formatted_rankings AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        actors,
        genre,
        RANK() OVER (PARTITION BY genre ORDER BY total_cast DESC) AS genre_rank
    FROM 
        movie_rankings
)

SELECT 
    movie_title,
    production_year,
    total_cast,
    actors,
    genre,
    genre_rank
FROM 
    formatted_rankings
WHERE 
    genre_rank <= 5
ORDER BY 
    genre, genre_rank;
