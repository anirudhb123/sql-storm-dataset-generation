WITH ranked_movies AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS person_name,
        movie_info.info AS genre_info,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY production_year DESC) AS rank,
        COUNT(cast_info.id) OVER (PARTITION BY title.id) AS cast_count
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id AND movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    LEFT JOIN 
        cast_info ON cast_info.movie_id = title.id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year > 2000
        AND aka_name.name IS NOT NULL
),
filtered_movies AS (
    SELECT 
        movie_title,
        person_name,
        genre_info,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank = 1
        AND cast_count > 5
)
SELECT 
    movie_title,
    person_name,
    genre_info,
    CAST(NULLIF(genre_info, '') AS VARCHAR(50)) AS genre_safe,
    CASE 
        WHEN genre_info IS NULL THEN 'No Genre'
        ELSE genre_info
    END AS genre_display,
    EXISTS (
        SELECT 1 
        FROM movie_keyword 
        WHERE movie_keyword.movie_id = (SELECT id FROM title WHERE title = filtered_movies.movie_title)
        AND keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%')
    ) AS is_action_movie
FROM 
    filtered_movies 
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(*) AS award_count 
     FROM 
        movie_info 
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'Awards') 
     GROUP BY 
        movie_id
    ) awards ON awards.movie_id = (SELECT id FROM title WHERE title = filtered_movies.movie_title)
WHERE 
    awards.award_count IS NULL OR awards.award_count > 0
ORDER BY 
    movie_title, person_name;

This SQL query retrieves a list of movies from the `title` table, filtering those produced after the year 2000 and having a cast of more than five members. It uses CTEs for organizing data about ranked movies and subsequently filtering them. It employs various constructs such as `ROW_NUMBER()`, `LEFT JOIN`, `NULLIF`, and a correlated subquery to determine whether a movie is categorized as an "Action" movie through keyword association. Additionally, it incorporates NULL logic to provide default messages for genre details. The end result is a structured output of movie titles, associated persons, genre information, and award counts.
