WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        K.keyword,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY T.id) AS rank
    FROM 
        title T
    JOIN 
        movie_keyword MK ON T.id = MK.movie_id
    JOIN 
        keyword K ON MK.keyword_id = K.id
),
MovieCast AS (
    SELECT 
        C.movie_id,
        COUNT(*) AS actor_count
    FROM 
        cast_info C
    JOIN 
        RankedMovies RM ON C.movie_id = RM.movie_id
    GROUP BY 
        C.movie_id
),
MostPopularMovies AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        MC.actor_count
    FROM 
        RankedMovies RM
    JOIN 
        MovieCast MC ON RM.movie_id = MC.movie_id
    WHERE 
        RM.rank <= 5
)
SELECT 
    M.title,
    M.production_year,
    M.actor_count,
    GROUP_CONCAT(DISTINCT P.name ORDER BY P.name) AS actors,
    COALESCE(GROUP_CONCAT(DISTINCT K.keyword ORDER BY K.keyword), 'No keywords') AS keywords
FROM 
    MostPopularMovies M
LEFT JOIN 
    cast_info C ON M.movie_id = C.movie_id
LEFT JOIN 
    aka_name P ON C.person_id = P.person_id
LEFT JOIN 
    movie_keyword MK ON M.movie_id = MK.movie_id
LEFT JOIN 
    keyword K ON MK.keyword_id = K.id
GROUP BY 
    M.movie_id, M.title, M.production_year, M.actor_count
ORDER BY 
    M.production_year DESC, M.actor_count DESC;
