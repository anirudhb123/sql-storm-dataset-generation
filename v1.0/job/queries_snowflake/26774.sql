WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank_per_year,
        COUNT(DISTINCT mci.company_id) AS company_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),
ActorsInTopMovies AS (
    SELECT 
        ak.name AS actor_name,
        tm.title,
        tm.production_year,
        tm.kind_id,
        COUNT(ci.id) AS appearance_count
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name, tm.title, tm.production_year, tm.kind_id
    ORDER BY 
        appearance_count DESC
)
SELECT 
    actor_name,
    title,
    production_year,
    kind_id,
    appearance_count
FROM 
    ActorsInTopMovies
WHERE 
    appearance_count > 1
ORDER BY 
    production_year DESC, appearance_count DESC;
