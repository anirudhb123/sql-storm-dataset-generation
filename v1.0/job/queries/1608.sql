
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank_by_year,
        a.id 
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        m.movie_title,
        m.production_year,
        cc.cast_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        CastCounts cc ON m.id = cc.movie_id
    WHERE 
        m.rank_by_year <= 5
)
SELECT 
    fm.movie_title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS cast_count,
    CASE 
        WHEN COALESCE(fm.cast_count, 0) > 10 THEN 'Large Cast'
        WHEN COALESCE(fm.cast_count, 0) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT COUNT(DISTINCT k.keyword)
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id IN (SELECT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'genre'))) AS genre_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC
OFFSET 0 
FETCH FIRST 10 ROWS ONLY;
