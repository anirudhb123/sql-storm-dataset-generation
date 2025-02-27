WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        aka_name.name AS person_name,
        COUNT(cast_info.id) AS cast_count,
        movie_info.info AS summary,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY movie_info.info_type_id) AS rank
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.person_id AND complete_cast.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    GROUP BY 
        title.id, title.title, aka_name.name, movie_info.info
)
SELECT 
    movie_id,
    movie_title,
    person_name,
    cast_count,
    summary
FROM 
    RankedMovies 
WHERE 
    rank = 1 
ORDER BY 
    cast_count DESC, movie_title;
