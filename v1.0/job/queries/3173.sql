WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id, 
        title.title AS movie_title, 
        title.production_year, 
        DENSE_RANK() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rank_within_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
), 
MovieActors AS (
    SELECT 
        title.id AS movie_id, 
        aka_name.name AS actor_name, 
        COUNT(cast_info.id) AS actor_count
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, aka_name.name
), 
MovieKeywords AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
)
SELECT 
    R.movie_id, 
    R.movie_title, 
    R.production_year, 
    M.actor_name, 
    M.actor_count, 
    K.keywords
FROM 
    RankedMovies R
LEFT JOIN 
    MovieActors M ON R.movie_id = M.movie_id
LEFT JOIN 
    MovieKeywords K ON R.movie_id = K.movie_id
WHERE 
    (M.actor_count > 2 OR M.actor_count IS NULL) 
    AND R.rank_within_year <= 10
ORDER BY 
    R.production_year DESC, 
    R.movie_title;
