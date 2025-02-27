WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cast.person_id) DESC) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info cast ON mt.id = cast.movie_id
    JOIN 
        aka_name ak ON cast.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000 
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name
),

PopularMovies AS (
    SELECT 
        DISTINCT movie_title,
        production_year,
        (SELECT STRING_AGG(actor_name, ', ') 
         FROM RankedMovies rm 
         WHERE rm.movie_title = rm.movie_title
         ORDER BY actor_rank) AS top_actors
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
)

SELECT 
    p.movie_title,
    p.production_year,
    p.top_actors,
    (SELECT COUNT(DISTINCT mc.company_id)
     FROM movie_companies mc
     JOIN movie_info mi ON mc.movie_id = mi.movie_id
     WHERE mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
     AND mc.movie_id = p.movie_title) AS company_count
FROM 
    PopularMovies p
ORDER BY 
    p.production_year DESC, 
    p.movie_title;
