WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY c.nr_order DESC) AS rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.movie_id) AS total_cast
    FROM 
        aka_title a
    JOIN 
        movie_info m ON a.id = m.movie_id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Drama%' OR info LIKE '%Action%')
), FilteredMovies AS (
    SELECT 
        *,
        (CASE 
            WHEN total_cast > 5 THEN 'Large Cast'
            WHEN total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END) AS cast_size_category
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
), MovieKeywords AS (
    SELECT 
        f.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_keyword mk ON f.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        f.title
)
SELECT 
    f.title,
    f.production_year,
    f.cast_size_category,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieKeywords mk ON f.title = mk.title
WHERE 
    f.production_year > 2000
ORDER BY 
    f.production_year DESC, f.title;
