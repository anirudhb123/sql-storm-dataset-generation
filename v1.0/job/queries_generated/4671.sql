WITH RankedMovies AS (
    SELECT 
        Title.title, 
        Title.production_year, 
        COUNT(DISTINCT Cast.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY Title.production_year ORDER BY COUNT(DISTINCT Cast.person_id) DESC) AS year_rank
    FROM 
        title AS Title
    JOIN 
        complete_cast AS CompleteCast ON Title.id = CompleteCast.movie_id
    JOIN 
        cast_info AS Cast ON CompleteCast.subject_id = Cast.id
    GROUP BY 
        Title.id
), 
MovieKeywords AS (
    SELECT 
        Movie.id AS movie_id, 
        STRING_AGG(Keyword.keyword, ', ') AS keywords
    FROM 
        aka_title AS Movie
    JOIN 
        movie_keyword AS MovieKeyword ON Movie.id = MovieKeyword.movie_id
    JOIN 
        keyword AS Keyword ON MovieKeyword.keyword_id = Keyword.id
    GROUP BY 
        Movie.id
)
SELECT 
    RM.title,
    RM.production_year,
    RM.actor_count,
    COALESCE(MK.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies AS RM
LEFT JOIN 
    MovieKeywords AS MK ON RM.title = MK.movie_id
WHERE 
    RM.year_rank <= 5 
    AND RM.actor_count > (SELECT AVG(actor_count) FROM RankedMovies) 
ORDER BY 
    RM.production_year DESC, RM.actor_count DESC;
