WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.person_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info ILIKE '%Oscar%'  -- Filtering for movies that have information mentioning "Oscar"
    GROUP BY 
        title.id
),
MovieRankings AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        DENSE_RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.cast_count,
    mr.rank,
    ARRAY_AGG(DISTINCT ki.keyword) AS associated_keywords
FROM 
    MovieRankings mr
LEFT JOIN 
    movie_keyword mk ON mr.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    mr.movie_id, mr.title, mr.production_year, mr.cast_count, mr.rank
ORDER BY 
    mr.rank;
