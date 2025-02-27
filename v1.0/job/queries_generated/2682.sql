WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    GROUP BY c.person_id
),
MovieDetails AS (
    SELECT 
        t.title,
        a.name AS actor_name,
        COUNT(k.keyword) AS keyword_count
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.title, a.name
),
TopActors AS (
    SELECT 
        amc.person_id,
        a.name,
        amc.movie_count
    FROM ActorMovieCount amc
    JOIN aka_name a ON amc.person_id = a.person_id
    WHERE amc.movie_count >= ALL (SELECT movie_count FROM ActorMovieCount)
)
SELECT 
    md.title,
    md.actor_name,
    md.keyword_count,
    COALESCE(tm.year_rank, 0) AS year_rank
FROM MovieDetails md
LEFT JOIN RankedMovies tm ON md.title = tm.title
JOIN TopActors ta ON md.actor_name = ta.name
WHERE md.keyword_count > 5
ORDER BY md.keyword_count DESC, md.title;
