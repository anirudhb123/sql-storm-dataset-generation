
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        aka_name.name AS actor_name,
        movie_info.info AS box_office_info,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY movie_info.info_type_id) AS rank
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
),

ActorMovies AS (
    SELECT 
        actor_name,
        LISTAGG(movie_title, ', ') WITHIN GROUP (ORDER BY movie_title) AS movie_titles,
        COUNT(movie_id) AS total_movies
    FROM 
        RankedMovies
    WHERE 
        rank = 1
    GROUP BY 
        actor_name
    ORDER BY 
        total_movies DESC
    LIMIT 10
),

KeywordMovies AS (
    SELECT 
        movie_id,
        LISTAGG(keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
)

SELECT 
    am.actor_name,
    am.movie_titles,
    km.keywords
FROM 
    ActorMovies am
LEFT JOIN 
    KeywordMovies km ON am.movie_titles LIKE '%' || km.movie_id || '%'
ORDER BY 
    am.total_movies DESC;
