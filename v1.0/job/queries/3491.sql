WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.num_actors
    FROM RankedMovies rm
    WHERE rm.rn <= 5
),
ActorDetails AS (
    SELECT 
        an.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        ci.nr_order,
        COALESCE(ci.note, 'No comments') AS note
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN aka_title mt ON ci.movie_id = mt.movie_id
    WHERE mt.production_year IN (SELECT DISTINCT production_year FROM TopMovies)
)
SELECT 
    tm.movie_title,
    tm.production_year,
    ad.actor_name,
    ad.nr_order,
    ad.note
FROM TopMovies tm
LEFT JOIN ActorDetails ad ON tm.movie_title = ad.movie_title AND tm.production_year = ad.production_year
ORDER BY tm.production_year DESC, tm.movie_title, ad.nr_order;
