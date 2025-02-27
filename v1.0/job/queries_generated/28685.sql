WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM title t
    JOIN aka_title at ON at.movie_id = t.imdb_id
),

TopRatedMovies AS (
    SELECT 
        mv.movie_title,
        mv.production_year,
        k.keyword,
        COUNT(cast.person_id) AS cast_count
    FROM RankedMovies mv
    JOIN movie_keyword mk ON mk.movie_id = mv.production_year  -- Assuming movie_id links to production_year for the sake of this benchmark
    JOIN keyword k ON k.id = mk.keyword_id
    JOIN complete_cast cc ON cc.movie_id = mk.movie_id
    JOIN cast_info cast ON cast.movie_id = cc.movie_id
    WHERE mv.rank <= 10
    GROUP BY mv.movie_title, mv.production_year, k.keyword
),

ActorKeywords AS (
    SELECT 
        a.name AS actor_name,
        ak.keyword,
        COUNT(DISTINCT mk.movie_id) AS movies_count
    FROM aka_name a
    JOIN cast_info ci ON ci.person_id = a.person_id
    JOIN movie_keyword mk ON mk.movie_id = ci.movie_id
    JOIN keyword ak ON ak.id = mk.keyword_id
    GROUP BY a.name, ak.keyword
    HAVING COUNT(DISTINCT mk.movie_id) > 5  -- Actors in more than 5 movies
)

SELECT 
    tm.movie_title,
    tm.production_year,
    COUNT(DISTINCT ak.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ak.keyword, ', ') AS keywords
FROM TopRatedMovies tm
JOIN ActorKeywords ak ON ak.keyword IN (SELECT DISTINCT keyword FROM TopRatedMovies WHERE movie_title = tm.movie_title)
GROUP BY tm.movie_title, tm.production_year
ORDER BY tm.production_year DESC, actor_count DESC;
