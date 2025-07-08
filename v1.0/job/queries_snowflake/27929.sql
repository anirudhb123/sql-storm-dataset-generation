
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.cast_count,
        m.actor_names,
        k.keyword AS movie_keyword
    FROM 
        RankedMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actor_names,
        movie_keyword,
        DENSE_RANK() OVER (ORDER BY cast_count DESC) AS dense_rank
    FROM 
        MoviesWithKeywords
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    m.cast_count,
    m.actor_names,
    m.movie_keyword
FROM 
    TopMovies m
WHERE 
    m.dense_rank <= 10
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
