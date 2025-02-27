
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),
MaxCast AS (
    SELECT 
        production_year,
        MAX(total_cast_members) AS max_cast
    FROM RankedMovies
    GROUP BY production_year
),
MoviesWithMaxCast AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast_members,
        rm.movie_id -- Added movie_id to select clause
    FROM RankedMovies rm
    JOIN MaxCast mc ON rm.production_year = mc.production_year AND rm.total_cast_members = mc.max_cast
),
ActorsInMaxCastMovies AS (
    SELECT 
        ak.name AS actor_name,
        rm.title,
        rm.production_year,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY ak.name) AS actor_rank
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN MoviesWithMaxCast rm ON ci.movie_id = rm.movie_id
)
SELECT 
    a.actor_name,
    m.title,
    m.production_year,
    COALESCE(a.actor_rank, 0) AS actor_rank,
    (SELECT COUNT(DISTINCT ci2.person_id)
     FROM cast_info ci2
     WHERE ci2.movie_id = m.movie_id) AS num_cast,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM MoviesWithMaxCast m
LEFT JOIN ActorsInMaxCastMovies a ON m.title = a.title AND m.production_year = a.production_year
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE m.production_year >= 2000 AND (m.title ILIKE '%Star%' OR m.title IS NULL)
GROUP BY a.actor_name, m.title, m.production_year, a.actor_rank, m.movie_id -- Added m.movie_id to group by clause
ORDER BY m.production_year DESC, a.actor_name NULLS LAST;
