
WITH MovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
HighProfileMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title, mt.production_year, ak.name
    HAVING 
        COUNT(DISTINCT k.keyword) > 3
),
TotalActorProfile AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT mt.id) AS total_movies,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY 
        ak.id, ak.name
)
SELECT 
    hpm.actor_name,
    hpm.title AS movie_title,
    hpm.production_year,
    tap.total_movies,
    tap.movies_list,
    mc.movie_count AS movies_with_more_than_5_roles
FROM 
    HighProfileMovies hpm
JOIN 
    TotalActorProfile tap ON hpm.actor_name = tap.actor_name
JOIN 
    MovieCounts mc ON mc.person_id = tap.actor_id
ORDER BY 
    hpm.production_year DESC, 
    hpm.title;
