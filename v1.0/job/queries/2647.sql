WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count >= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        FilteredMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
AggregatedKeywords AS (
    SELECT 
        title,
        STRING_AGG(keyword, ', ') AS all_keywords
    FROM 
        MovieKeywords
    GROUP BY 
        title
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    COALESCE(a.all_keywords, 'No keywords') AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    AggregatedKeywords a ON f.title = a.title
WHERE 
    f.production_year IN (
        SELECT 
            DISTINCT production_year 
        FROM 
            FilteredMovies 
        WHERE 
            cast_count >= 5
    )
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
