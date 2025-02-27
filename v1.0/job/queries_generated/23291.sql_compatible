
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CASE 
            WHEN mt.production_year IS NULL THEN 'Unknown Year'
            WHEN mt.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS period,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN mt.production_year IS NULL THEN 'Unknown Year'
                WHEN mt.production_year < 2000 THEN 'Classic'
                ELSE 'Modern'
            END 
            ORDER BY mt.production_year) AS movie_rank
    FROM 
        aka_title mt
),
TotalMoviesPerYear AS (
    SELECT 
        production_year,
        COUNT(*) AS total_movies
    FROM 
        RankedMovies 
    WHERE 
        production_year IS NOT NULL
    GROUP BY 
        production_year
),
PersonMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ak.person_id) AS number_of_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id AND ak.name IS NOT NULL
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        RM.period,
        COALESCE(PM.number_of_actors, 0) AS actor_count,
        COALESCE(MK.keywords, 'No Keywords') AS keywords,
        TMP.total_movies
    FROM 
        RankedMovies RM
    LEFT JOIN 
        PersonMovies PM ON RM.movie_id = PM.movie_id
    LEFT JOIN 
        MovieKeywords MK ON RM.movie_id = MK.movie_id
    LEFT JOIN 
        TotalMoviesPerYear TMP ON RM.production_year = TMP.production_year
)

SELECT 
    FR.movie_id,
    FR.title,
    FR.production_year,
    FR.period,
    FR.actor_count,
    FR.keywords,
    FR.total_movies,
    CASE 
        WHEN FR.actor_count < 5 THEN 'Low Cast'
        WHEN FR.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'High Cast'
    END AS cast_category,
    CASE 
        WHEN FR.total_movies IS NULL AND FR.period = 'Unknown Year' THEN 'Insufficient Data'
        ELSE 'Data Available'
    END AS data_status,
    CASE 
        WHEN FR.actor_count = 0 THEN NULL 
        ELSE (SELECT AVG(number_of_actors) FROM PersonMovies)
    END AS average_actor_count
FROM 
    FinalResults FR
WHERE 
    FR.total_movies IS NOT NULL
ORDER BY 
    FR.production_year DESC, FR.actor_count DESC
LIMIT 50;
