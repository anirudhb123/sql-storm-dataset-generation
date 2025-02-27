WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS all_cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords
    FROM 
        aka_title mt
    INNER JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        all_cast_names,
        movie_keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    t.movie_title,
    t.production_year,
    t.cast_count,
    t.all_cast_names,
    t.movie_keywords
FROM 
    TopMovies t
WHERE 
    t.rank <= 10
ORDER BY 
    t.cast_count DESC, t.production_year DESC;
