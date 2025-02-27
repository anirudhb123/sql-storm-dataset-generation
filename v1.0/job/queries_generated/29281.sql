WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
TopRankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_cast,
        cast_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    TR.movie_id,
    TR.movie_title,
    TR.production_year,
    TR.total_cast,
    TR.cast_names,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS movie_keywords,
    COUNT(DISTINCT mi.id) AS info_count
FROM 
    TopRankedMovies TR
LEFT JOIN 
    movie_keyword mk ON TR.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON TR.movie_id = mi.movie_id
WHERE 
    TR.rank <= 10
GROUP BY 
    TR.movie_id, TR.movie_title, TR.production_year, TR.total_cast, TR.cast_names
ORDER BY 
    TR.rank;
