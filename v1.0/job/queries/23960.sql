WITH RecursiveMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(EXTRACT(YEAR FROM cast('2024-10-01' as date)) - t.production_year, 0) AS age,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ka.name AS actor_name,
        ka.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT tt.title, ', ') AS movies_list
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        title tt ON ci.movie_id = tt.id
    GROUP BY 
        ka.name, ka.person_id
),
MovieGenre AS (
    SELECT 
        mt.movie_id,
        kt.keyword AS genre
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.age,
        CASE 
            WHEN rm.age < 10 THEN 'Recent'
            WHEN rm.age BETWEEN 10 AND 20 THEN 'Moderate Age'
            ELSE 'Classic'
        END AS age_category
    FROM 
        RecursiveMovies rm
    WHERE 
        rm.age IS NOT NULL
),
OuterJoinGenres AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.age_category,
        COALESCE(mg.genre, 'Unknown') AS genre
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieGenre mg ON fm.movie_id = mg.movie_id
)
SELECT 
    od.actor_name,
    o.movie_id,
    o.title,
    o.age_category,
    o.genre,
    od.total_movies,
    od.movies_list
FROM 
    ActorDetails od
JOIN 
    OuterJoinGenres o ON od.total_movies > 1 AND o.age_category = 'Recent'
ORDER BY 
    od.total_movies DESC,
    o.title ASC
LIMIT 10;