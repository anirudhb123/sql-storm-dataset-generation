WITH MovieAwards AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        COUNT(DISTINCT movie_info.info) AS award_count,
        STRING_AGG(DISTINCT movie_info.info, ', ') AS awards_list
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    WHERE 
        movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY 
        title.id, title.title
),
PersonAndMovies AS (
    SELECT 
        aka_name.person_id,
        aka_name.name AS actor_name,
        cast_info.movie_id,
        title.title AS movie_title,
        movie_info.info AS movie_info
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    JOIN 
        title ON cast_info.movie_id = title.id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    WHERE 
        movie_info.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Genre', 'Plot'))
),
RankedActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movies_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT movie_id) DESC) AS rank
    FROM 
        PersonAndMovies
    GROUP BY 
        actor_name
)
SELECT 
    ra.actor_name,
    ra.movies_count,
    ma.movie_id,
    ma.title,
    ma.award_count,
    ma.awards_list
FROM 
    RankedActors ra
JOIN 
    MovieAwards ma ON ra.movies_count > 1
WHERE 
    ra.rank <= 10
ORDER BY 
    ra.movies_count DESC, ma.award_count DESC;
