WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.title, t.production_year
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(NULLIF(rm.cast_count, 0), 'No cast information') AS cast_count,
    ak.name AS actor_name,
    ak.imdb_index AS actor_imdb_index
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info ci ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = ci.movie_id)
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    rm.rank_within_year <= 5
    AND rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;

-- Additional statistics about keywords associated with the movies
WITH MovieKeywordStats AS (
    SELECT 
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
)

SELECT 
    t.title,
    mks.keyword_count,
    CASE 
        WHEN mks.keyword_count > 10 THEN 'Popular'
        WHEN mks.keyword_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Known'
    END AS movie_popularity
FROM 
    MovieKeywordStats mks
JOIN 
    aka_title t ON mks.movie_id = t.id
WHERE 
    t.production_year < 2020
ORDER BY 
    mks.keyword_count DESC;
