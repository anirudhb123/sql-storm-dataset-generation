WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn,
        t.production_year,
        t.kind_id
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
ActorMovieStats AS (
    SELECT 
        akt.actor_name,
        COUNT(DISTINCT akt.movie_title) AS total_movies,
        MAX(akt.production_year) AS latest_movie,
        MIN(akt.production_year) AS earliest_movie
    FROM RankedMovies akt
    WHERE akt.rn = 1
    GROUP BY akt.actor_name
),
MovieKeywordStats AS (
    SELECT 
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.movie_id = mk.movie_id
    GROUP BY t.id
)
SELECT 
    am.actor_name,
    am.total_movies,
    am.latest_movie,
    am.earliest_movie,
    COALESCE(mks.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN am.total_movies > 10 THEN 'Prolific Actor'
        WHEN am.total_movies BETWEEN 5 AND 10 THEN 'Average Actor'
        ELSE 'Emerging Actor'
    END AS actor_category,
    CASE 
        WHEN am.latest_movie IS NOT NULL AND am.earliest_movie IS NOT NULL THEN 
            am.latest_movie - am.earliest_movie
        ELSE 
            NULL 
    END AS movie_span
FROM ActorMovieStats am
LEFT JOIN MovieKeywordStats mks ON am.latest_movie = mks.movie_id
WHERE am.latest_movie IS NOT NULL
ORDER BY am.total_movies DESC, am.actor_name;
