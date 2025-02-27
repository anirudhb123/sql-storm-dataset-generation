WITH RankedMovies AS (
    SELECT 
        T.title,
        T.production_year,
        T.id AS movie_id,
        AK.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY T.id ORDER BY CA.nr_order) AS actor_rank
    FROM 
        aka_title T
    JOIN 
        cast_info CA ON T.id = CA.movie_id
    JOIN 
        aka_name AK ON CA.person_id = AK.person_id
    WHERE 
        T.production_year >= 2000 
        AND AK.name IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MoviesWithKeywords AS (
    SELECT 
        M.title,
        M.production_year,
        array_agg(K.keyword) AS keywords
    FROM 
        aka_title M
    JOIN 
        movie_keyword MK ON M.id = MK.movie_id
    JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE 
        M.production_year >= 2000
    GROUP BY 
        M.title, M.production_year
),
FinalResults AS (
    SELECT 
        R.actor_name,
        R.movie_count,
        M.title,
        M.production_year,
        M.keywords
    FROM 
        TopActors R
    LEFT JOIN 
        MoviesWithKeywords M ON R.movie_count > 0
)

SELECT 
    actor_name,
    movie_count,
    title,
    production_year,
    keywords
FROM 
    FinalResults
ORDER BY 
    movie_count DESC, production_year DESC;