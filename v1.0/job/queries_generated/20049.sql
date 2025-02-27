WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank_by_movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL 
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieGenres AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        pa.actor_name,
        mg.genres,
        COALESCE(rm.rank_by_cast, 0) AS rank_by_cast,
        COALESCE(pa.rank_by_movies, 0) AS rank_by_movies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularActors pa ON pa.movie_count = rm.cast_count
    LEFT JOIN 
        MovieGenres mg ON mg.movie_id = rm.id
    WHERE 
        (rm.production_year > 2010 OR rm.rank_by_cast <= 10)
        AND (pa.actor_name IS NULL OR pa.actor_name LIKE '%Smith%')
)
SELECT 
    title,
    production_year,
    cast_count,
    actor_name,
    genres,
    rank_by_cast,
    rank_by_movies
FROM 
    FinalResults
ORDER BY 
    production_year DESC, rank_by_cast ASC
LIMIT 100;

