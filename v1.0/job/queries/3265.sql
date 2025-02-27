WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
GenreCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    COALESCE(gc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN rm.rank_by_cast <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS ranking_category
FROM 
    RankedMovies rm
LEFT JOIN 
    GenreCount gc ON rm.movie_id = gc.movie_id
WHERE 
    rm.production_year IS NOT NULL 
    AND (gc.keyword_count > 5 OR gc.keyword_count IS NULL)
ORDER BY 
    rm.production_year DESC, 
    ranking_category;
