WITH RecursiveMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        aka_name.name AS actor_name,
        movie_info.info AS movie_info_text,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_name.name) AS actor_order
    FROM 
        title
    LEFT JOIN aka_title ON title.id = aka_title.movie_id
    LEFT JOIN cast_info ON aka_title.id = cast_info.movie_id
    LEFT JOIN aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN movie_info ON title.id = movie_info.movie_id
    WHERE 
        movie_info.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Synopsis%')
), MovieActorAggregation AS (
    SELECT 
        movie_id,
        movie_title,
        STRING_AGG(actor_name, ', ') WITHIN GROUP (ORDER BY actor_order) AS actors
    FROM 
        RecursiveMovies
    GROUP BY 
        movie_id, movie_title
), MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword 
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
), FinalOutput AS (
    SELECT 
        ma.movie_title,
        ma.actors,
        mk.keywords,
        CASE 
            WHEN mk.keywords IS NULL THEN 'No Keywords'
            ELSE mk.keywords 
        END AS keywords_display
    FROM 
        MovieActorAggregation ma
    LEFT JOIN MovieKeywords mk ON ma.movie_id = mk.movie_id
)
SELECT 
    movie_title,
    actors,
    keywords_display,
    CASE 
        WHEN LENGTH(movie_title) % 2 = 0 THEN 'Even Length'
        ELSE 'Odd Length'
    END AS title_length_category,
    (SELECT COUNT(*) 
     FROM movie_info 
     WHERE movie_id = (SELECT movie_id FROM MovieActorAggregation WHERE movie_title = ma.movie_title)
     AND info_type_id = (SELECT id FROM info_type WHERE info LIKE '%Director%')) AS director_count
FROM 
    FinalOutput ma
ORDER BY 
    title_length_category DESC, 
    actors ASC NULLS LAST
LIMIT 100 OFFSET 0;
