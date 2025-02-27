WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY title.production_year) AS total_movies
    FROM title
    WHERE title.production_year IS NOT NULL
),
QualifiedActors AS (
    SELECT 
        aka_name.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count
    FROM aka_name
    JOIN cast_info ON aka_name.person_id = cast_info.person_id
    GROUP BY aka_name.person_id, aka_name.name
    HAVING COUNT(DISTINCT cast_info.movie_id) > 5
),
MoviesWithCompany AS (
    SELECT 
        mk.movie_id,
        string_agg(DISTINCT company_name.name, ', ') AS company_names,
        COUNT(DISTINCT movie_companies.company_id) AS company_count
    FROM movie_keyword mk
    JOIN movie_companies ON mk.movie_id = movie_companies.movie_id
    JOIN company_name ON movie_companies.company_id = company_name.id
    GROUP BY mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mwc.company_names, 'No Companies') AS companies,
        mwc.company_count
    FROM RankedMovies rm
    LEFT JOIN MoviesWithCompany mwc ON rm.movie_id = mwc.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.companies,
    dmi.company_count,
    COALESCE(qa.name, 'Unknown Actor') AS actor_name,
    qa.movie_count AS actor_movie_count,
    CASE 
        WHEN qa.movie_count > 10 THEN 'Frequent Actor' 
        ELSE 'Occasional Actor' 
    END AS actor_frequency
FROM DetailedMovieInfo dmi
LEFT JOIN QualifiedActors qa ON dmi.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = qa.person_id)
WHERE dmi.company_count > 0
ORDER BY dmi.production_year DESC, dmi.title;
