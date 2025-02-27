WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mci.company_id DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
), 
ActorMovies AS (
    SELECT 
        ka.person_id, 
        ka.name, 
        rm.movie_id, 
        rm.title AS movie_title, 
        rm.production_year
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
), 
MovieDetails AS (
    SELECT 
        am.person_id, 
        am.name, 
        am.movie_id, 
        am.movie_title, 
        am.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ci.note AS role_note
    FROM 
        ActorMovies am
    LEFT JOIN 
        movie_keyword mk ON am.movie_id = mk.movie_id
    LEFT JOIN 
        role_type ci ON ci.id = (SELECT role_id FROM cast_info WHERE movie_id = am.movie_id AND person_id = am.person_id LIMIT 1)
)
SELECT 
    md.name AS actor_name, 
    COUNT(DISTINCT md.movie_id) AS total_movies,
    STRING_AGG(DISTINCT md.movie_title, ', ') AS movies,
    MAX(md.production_year) AS latest_movie_year,
    MIN(md.production_year) AS earliest_movie_year,
    COUNT(DISTINCT md.keyword) AS unique_keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
GROUP BY 
    md.name
HAVING 
    COUNT(DISTINCT md.movie_id) > 5 AND 
    MAX(md.production_year) IS NOT NULL
ORDER BY 
    total_movies DESC;
