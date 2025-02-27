WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),

PopularActors AS (
    SELECT 
        an.id AS actor_id,
        an.name,
        COUNT(ci.movie_id) AS movie_count
    FROM aka_name an
    JOIN cast_info ci ON an.person_id = ci.person_id
    GROUP BY an.id, an.name
    HAVING COUNT(ci.movie_id) > 5
),

DetailedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        pa.name AS popular_actor_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM RankedMovies rm
    LEFT JOIN PopularActors pa ON pa.movie_id IN (
        SELECT movie_id
        FROM cast_info
        WHERE person_id IN (SELECT person_id FROM aka_name)
    )
    LEFT JOIN movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    WHERE rm.rank <= 10
    GROUP BY rm.movie_id, rm.title, rm.production_year, pa.name
)

SELECT 
    dmi.movie_id,
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.popular_actor_name,
    COALESCE(dmi.keywords, 'No keywords') AS keywords
FROM DetailedMovieInfo dmi
ORDER BY dmi.production_year DESC, dmi.cast_count DESC;
