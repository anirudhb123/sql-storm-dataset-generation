WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorDetails AS (
    SELECT 
        ak.name,
        ak.person_id,
        tm.title,
        tm.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY tm.production_year DESC) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        TopMovies tm ON ci.movie_id = tm.movie_id
)
SELECT 
    ad.name AS actor_name,
    ad.title AS movie_title,
    ad.production_year,
    COUNT(DISTINCT ad.movie_rank) AS appearances,
    STRING_AGG(ad.title, ', ') AS movies
FROM 
    ActorDetails ad
GROUP BY 
    ad.name, ad.title, ad.production_year
HAVING 
    COUNT(DISTINCT ad.movie_rank) > 1
ORDER BY 
    appearances DESC
LIMIT 10;
