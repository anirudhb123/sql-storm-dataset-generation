
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
),
MovieStats AS (
    SELECT 
        f.title,
        f.production_year,
        f.cast_count,
        COALESCE(SUM(m.info_type_id), 0) AS info_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_info m ON f.title = m.title
    GROUP BY 
        f.title, f.production_year, f.cast_count
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.info_count,
    CASE 
        WHEN ms.info_count > 10 THEN 'Highly Detailed'
        WHEN ms.info_count BETWEEN 5 AND 10 THEN 'Moderately Detailed'
        ELSE 'Sparsely Detailed'
    END AS detail_level
FROM 
    MovieStats ms
WHERE 
    ms.cast_count > 0
ORDER BY 
    ms.production_year DESC,
    ms.cast_count DESC
LIMIT 10
OFFSET 5;
