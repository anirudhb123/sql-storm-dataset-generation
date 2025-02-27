WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year ASC) AS year_rank,
        COUNT(c.id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 10
        AND rm.production_year BETWEEN 2000 AND 2020
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
    ORDER BY 
        keyword_count DESC
    LIMIT 5
),
MovieDetails AS (
    SELECT 
        fm.title,
        fm.production_year,
        COALESCE(tk.keyword_count, 0) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        TopKeywords tk ON fm.id = tk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 3 THEN 'Highly Tagged'
        WHEN md.keyword_count BETWEEN 1 AND 3 THEN 'Moderately Tagged'
        ELSE 'Not Tagged'
    END AS tag_status,
    (SELECT STRING_AGG(DISTINCT c.note, ', ') 
     FROM cast_info c 
     WHERE c.movie_id = (SELECT id FROM aka_title WHERE title = md.title LIMIT 1)
    ) AS cast_notes
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;
