
WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        a.title, t.production_year
), FilteredMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(mk.total_keywords, 0) AS total_keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    (SELECT 
        mk.movie_id,
        SUM(COUNT(mk.id)) AS total_keywords
     FROM 
        movie_keyword mk
     JOIN 
        keyword k ON mk.keyword_id = k.id
     GROUP BY 
        mk.movie_id) mk ON mk.movie_id = (
        SELECT 
            m.id 
        FROM 
            aka_title a
        JOIN 
            title m ON a.movie_id = m.id
        WHERE 
            a.title = fm.title AND m.production_year = fm.production_year
        LIMIT 1
    )
WHERE 
    fm.cast_count IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
