WITH RankedActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank,
        COUNT(ci.movie_id) AS total_movies
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
MoviesWithGenres AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        kt.kind AS genre,
        at.production_year,
        RANK() OVER (PARTITION BY kg.movie_id ORDER BY kg.keyword) AS genre_rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
),
HighRatedMovies AS (
    SELECT 
        mt.movie_id,
        mt.info AS rating_info
    FROM 
        movie_info mt
    JOIN 
        info_type it ON mt.info_type_id = it.id
    WHERE 
        it.info = 'rating' AND mt.info LIKE '8.%' -- High-rated movies
),
ActorDetails AS (
    SELECT 
        ra.name AS actor_name,
        mw.title AS movie_title,
        mw.production_year,
        COALESCE(hr.rating_info, 'N/A') AS rating_info,
        ROW_NUMBER() OVER (PARTITION BY ra.person_id ORDER BY mw.production_year DESC) AS latest_movie_rank
    FROM 
        RankedActors ra
    INNER JOIN 
        cast_info ci ON ra.person_id = ci.person_id
    INNER JOIN 
        MoviesWithGenres mw ON ci.movie_id = mw.movie_id
    LEFT JOIN 
        HighRatedMovies hr ON mw.movie_id = hr.movie_id
)
SELECT 
    ad.actor_name,
    ad.movie_title,
    ad.production_year,
    ad.rating_info,
    STRING_AGG(DISTINCT mw.genre, ', ') AS genres
FROM 
    ActorDetails ad
JOIN 
    MoviesWithGenres mw ON ad.movie_title = mw.title AND ad.production_year = mw.production_year
WHERE 
    ad.latest_movie_rank = 1
GROUP BY 
    ad.actor_name, ad.movie_title, ad.production_year, ad.rating_info
HAVING 
    COUNT(mw.genre) > 1 -- filtering actors having movies with multiple genres
ORDER BY 
    ad.actor_name, ad.production_year DESC;
