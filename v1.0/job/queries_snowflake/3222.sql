
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
PopularActors AS (
    SELECT 
        ak.name, 
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        a.title,
        k.keyword
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    DISTINCT m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ka.name) AS popular_actors,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM 
    RankedMovies m
LEFT JOIN 
    PopularActors ka ON ka.movies_count > 5 AND ka.movies_count = m.cast_count
LEFT JOIN 
    MoviesWithKeywords kw ON m.title = kw.title
WHERE 
    m.rank <= 10
GROUP BY 
    m.title, m.production_year
ORDER BY 
    m.production_year DESC, popular_actors DESC;
