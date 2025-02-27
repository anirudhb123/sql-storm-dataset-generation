WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS movie_rank
    FROM title
    WHERE title.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorMovieCount AS (
    SELECT 
        aka_name.name AS actor_name,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count
    FROM aka_name
    JOIN cast_info ON aka_name.person_id = cast_info.person_id
    GROUP BY aka_name.name
),
MovieCompAgg AS (
    SELECT 
        m.title AS movie_title,
        c.name AS company_name,
        COUNT(mc.id) AS company_count
    FROM aka_title m
    LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    GROUP BY m.title, c.name
),
HighRatedActors AS (
    SELECT 
        actor_name, 
        movie_count
    FROM ActorMovieCount
    WHERE movie_count > (SELECT AVG(movie_count) FROM ActorMovieCount)
)

SELECT 
    rm.movie_title,
    rm.production_year,
    h.actor_name,
    COALESCE(mca.company_name, 'Independent') AS production_company,
    h.movie_count
FROM RankedMovies rm
JOIN HighRatedActors h ON rm.movie_rank <= 5
LEFT JOIN MovieCompAgg mca ON rm.movie_title = mca.movie_title
WHERE rm.production_year > 2000
ORDER BY rm.production_year DESC, rm.movie_title;
