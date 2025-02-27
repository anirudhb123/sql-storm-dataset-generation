WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_length_rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.title = a.name
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND a.name IS NOT NULL
),
HighRatedMovies AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
    HAVING 
        COUNT(DISTINCT keyword_id) >= 3
),
MoviesWithCast AS (
    SELECT 
        cm.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.person_id = ci.person_id
    GROUP BY 
        cm.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.aka_id,
        rm.title,
        rm.production_year,
        h.keyword_count,
        mc.cast_count
    FROM 
        RankedMovies rm
    JOIN 
        HighRatedMovies h ON rm.title_id = h.movie_id
    LEFT JOIN 
        MoviesWithCast mc ON rm.title_id = mc.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.keyword_count,
    COALESCE(mc.cast_count, 0) AS cast_count,
    CASE 
        WHEN f.keyword_count > 5 THEN 'High'
        WHEN f.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS Keyword_Category,
    STRING_AGG(DISTINCT m.title, ', ') FILTER (WHERE m.production_year BETWEEN 2000 AND 2010) AS Titles_2000_2010
FROM 
    FilteredMovies f
LEFT JOIN 
    aka_title m ON f.title = m.title AND f.production_year = m.production_year
GROUP BY 
    f.title, f.production_year, f.keyword_count, mc.cast_count
ORDER BY 
    f.production_year DESC, f.keyword_count DESC NULLS LAST
LIMIT 50;
