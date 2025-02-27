WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    INNER JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    INNER JOIN 
        keyword kw ON mk.keyword_id = kw.id
    INNER JOIN 
        cast_info ci ON mt.id = ci.movie_id
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    hm.cast_count,
    hm.actors,
    hm.keywords
FROM 
    HighCastMovies hm
WHERE 
    hm.rank <= 10
ORDER BY 
    hm.production_year DESC;