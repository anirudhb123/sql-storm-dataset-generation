WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_within_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rank_within_year,
        total_cast_members
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 3
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.total_cast_members,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN f.total_cast_members > 10 THEN 'Large Cast'
        WHEN f.total_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_description,
    CASE
        WHEN f.production_year IS NULL THEN 'YEAR_NOT_SPECIFIED'
        ELSE TO_CHAR(f.production_year, '9999')
    END AS formatted_year
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieKeywordCounts mkc ON f.movie_id = mkc.movie_id
ORDER BY 
    f.production_year DESC, 
    f.title ASC
LIMIT 10
OFFSET 5;
