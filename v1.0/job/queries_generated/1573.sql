WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY AVG(p.rating) DESC) AS rank
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) p ON t.id = p.movie_id
    GROUP BY t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(ci.movie_id) AS movie_count
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    WHERE ci.nr_order = 1
    GROUP BY ka.person_id, ka.name
    HAVING COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        pa.name AS top_actor
    FROM RankedMovies rm
    LEFT JOIN cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN PopularActors pa ON ci.person_id = pa.person_id
    WHERE rm.rank <= 5
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.top_actor, 'No leading actor') AS leading_actor,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = md.movie_id) AS keywords
FROM MovieDetails md
ORDER BY md.production_year DESC, md.title;
