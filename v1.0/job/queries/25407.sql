
WITH MovieTitles AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        title.kind_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS full_cast_names
    FROM 
        title
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id AND movie_info.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'summary'
        )
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year > 2000
    GROUP BY 
        title.id, title.title, title.production_year, title.kind_id
),
TopMovies AS (
    SELECT 
        mt.movie_id,
        mt.movie_title,
        mt.production_year,
        mt.cast_count,
        mt.full_cast_names,
        ROW_NUMBER() OVER (ORDER BY mt.cast_count DESC) AS rank
    FROM 
        MovieTitles mt
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.full_cast_names,
    k.keyword AS movie_keyword
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
