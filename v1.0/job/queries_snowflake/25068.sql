
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT ak.name), ', ') AS aka_names,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
MovieRankings AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        aka_names,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY movie_keyword ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    mr.movie_title,
    mr.production_year,
    mr.movie_keyword,
    mr.aka_names,
    mr.cast_count
FROM 
    MovieRankings mr
WHERE 
    mr.rank <= 5
ORDER BY 
    mr.movie_keyword, mr.cast_count DESC;
