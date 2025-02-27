WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast_count <= 5
),
MostFrequentKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 1
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(SUM(mk.keyword_count), 0) AS related_keywords,
    CASE 
        WHEN fm.total_cast > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    MostFrequentKeywords mk ON fm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
GROUP BY 
    fm.title, fm.production_year, fm.total_cast
ORDER BY 
    fm.production_year DESC, related_keywords DESC;
