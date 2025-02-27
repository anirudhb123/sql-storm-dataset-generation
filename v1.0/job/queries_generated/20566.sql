WITH RecursiveMovieData AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        tc.kind AS movie_genre,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_in_movies
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON ak.person_id = a.person_id
    JOIN 
        aka_title t ON t.id = a.movie_id
    JOIN 
        kind_type tc ON tc.id = t.kind_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredGenres AS (
    SELECT 
        DISTINCT movie_genre 
    FROM 
        RecursiveMovieData
    WHERE 
        movie_genre IS NOT NULL
        AND movie_genre NOT IN ('Documentary', 'Short')
),
ActorStatistics AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        AVG(production_year) AS avg_production_year,
        MAX(rank_in_movies) AS highest_rank
    FROM 
        RecursiveMovieData
    WHERE 
        movie_genre IN (SELECT movie_genre FROM FilteredGenres)
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    as1.actor_name,
    as1.total_movies,
    as1.avg_production_year,
    as1.highest_rank,
    (SELECT COUNT(*) 
     FROM actor_statistics as2 
     WHERE as2.total_movies > as1.total_movies) AS more_movies_than,
    CASE 
        WHEN as1.total_movies IS NULL THEN 'No Movies'
        WHEN as1.total_movies > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS achievement_status
FROM 
    ActorStatistics as1
LEFT JOIN 
    (SELECT * FROM company_name WHERE country_code IS NOT NULL) cn ON cn.imdb_id IS NOT NULL
WHERE 
    as1.avg_production_year < 2000
ORDER BY 
    as1.total_movies DESC, 
    as1.avg_production_year ASC
LIMIT 20;
