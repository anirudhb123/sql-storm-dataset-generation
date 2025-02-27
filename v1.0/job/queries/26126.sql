WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS full_cast,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
        AND title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.id, title.title, title.production_year
    HAVING 
        COUNT(DISTINCT cast_info.person_id) > 5
),

PopularGenres AS (
    SELECT 
        kind_type.kind AS genre,
        COUNT(movie_companies.movie_id) AS genre_count
    FROM 
        movie_companies
    JOIN 
        aka_title ON movie_companies.movie_id = aka_title.movie_id
    JOIN 
        kind_type ON aka_title.kind_id = kind_type.id
    GROUP BY 
        kind_type.kind
    ORDER BY 
        genre_count DESC
    LIMIT 10
)

SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.full_cast,
    rm.keywords,
    pg.genre,
    pg.genre_count
FROM 
    RankedMovies AS rm
JOIN 
    PopularGenres AS pg ON rm.title LIKE '%' || pg.genre || '%'
ORDER BY 
    rm.rank
LIMIT 20;