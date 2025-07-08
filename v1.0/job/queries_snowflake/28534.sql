
WITH MovieCharacterCounts AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        COUNT(DISTINCT cast_info.person_id) AS character_count
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title
),

TopMoviesByCharacters AS (
    SELECT 
        movie_id,
        movie_title,
        character_count,
        RANK() OVER (ORDER BY character_count DESC) AS rank
    FROM 
        MovieCharacterCounts
),

MovieKeywords AS (
    SELECT 
        title.id AS movie_id,
        LISTAGG(keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        title.id
)

SELECT 
    t.movie_id,
    t.movie_title,
    t.character_count,
    k.keywords
FROM 
    TopMoviesByCharacters t
LEFT JOIN 
    MovieKeywords k ON t.movie_id = k.movie_id
WHERE 
    t.rank <= 10
ORDER BY 
    t.character_count DESC;
