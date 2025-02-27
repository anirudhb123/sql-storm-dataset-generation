WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY a.id) AS total_cast,
        COUNT(DISTINCT mk.keyword) OVER (PARTITION BY a.id) AS total_keywords,
        ROW_NUMBER() OVER (ORDER BY a.production_year DESC, a.title) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL AND
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
        AND a.title NOT LIKE '%untitled%'
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        total_keywords,
        rank
    FROM 
        RankedMovies
    WHERE 
        total_cast > 10 AND
        EXISTS (
            SELECT 1 
            FROM aka_name an 
            WHERE an.id IN (SELECT person_id FROM cast_info WHERE movie_id = RankedMovies.id)
            AND an.name ILIKE '%John%'
        )
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        total_keywords,
        rank,
        LEAD(movie_title) OVER (ORDER BY rank) AS next_movie
    FROM 
        FilteredMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.total_keywords,
    tm.next_movie,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year >= 2000 AND tm.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    TopMovies tm
WHERE 
    rank <= 20
ORDER BY 
    total_cast DESC NULLS LAST, 
    production_year ASC;

-- Additional statistical information not necessarily part of the main query but useful for benchmarking
SELECT 
    COUNT(*) AS total_movies,
    AVG(total_cast) AS avg_cast_size,
    MAX(total_keywords) AS max_keywords,
    SUM(CASE WHEN production_year < 2000 THEN 1 ELSE 0 END) AS classic_count
FROM 
    FilteredMovies;

-- A bizarre corner case: check for movies with conflicting titles or any anomalies in single-letter words
SELECT 
    movie_title,
    COUNT(*) AS occurrence
FROM 
    aka_title
WHERE 
    LENGTH(movie_title) - LENGTH(REPLACE(movie_title, 'a', '')) > 0 OR
    LENGTH(movie_title) - LENGTH(REPLACE(movie_title, 'I', '')) > 0
GROUP BY 
    movie_title
HAVING 
    COUNT(*) > 1 
ORDER BY 
    occurrence DESC;
