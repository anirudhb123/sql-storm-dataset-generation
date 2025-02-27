WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mk.keyword,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year > 2000
        AND mk.keyword ILIKE '%Action%'
    GROUP BY 
        mt.id, mt.title, mt.production_year, mk.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        rc.movie_id,
        rc.title,
        rc.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopMovies rc ON ci.movie_id = rc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT( DISTINCT ad.actor_id) AS num_actors,
    STRING_AGG(DISTINCT ad.actor_name, ', ') AS actor_list
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.movie_id = ad.movie_id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, num_actors DESC;
