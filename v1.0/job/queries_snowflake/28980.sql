
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        km.keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword km ON mk.keyword_id = km.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
        AND km.keyword ILIKE '%action%' 
    GROUP BY 
        mt.id, mt.title, mt.production_year, km.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count,
        actors,
        RANK() OVER (PARTITION BY keyword ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    cast_count,
    actors
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    keyword, cast_count DESC;
