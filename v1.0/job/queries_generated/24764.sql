WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
UniqueKeywords AS (
    SELECT DISTINCT 
        k.keyword, 
        mk.movie_id
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
),
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year,
        COALESCE(STRING_AGG(uk.keyword, ', '), 'No Keywords') AS keywords,
        COUNT(DISTINCT ci.person_id) AS unique_cast_members,
        COUNT(DISTINCT mc.company_id) AS unique_companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        UniqueKeywords uk ON tm.movie_id = uk.movie_id
    GROUP BY 
        tm.title, 
        tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.unique_cast_members,
    md.unique_companies,
    COUNT(mk.movie_id) AS keyword_count,
    CASE 
        WHEN md.unique_companies > 0 THEN 'Produced'
        ELSE 'Not Produced'
    END AS production_status,
    CASE WHEN md.production_year IS NULL OR md.production_year < 1900 
         THEN 'Unknown Year' 
         ELSE 'Known Year' 
    END AS year_status
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.production_year IS NOT NULL AND mk.movie_id = md.movie_id
WHERE 
    (md.keywords IS NOT NULL AND NOT md.keywords = 'No Keywords') 
    OR (md.unique_cast_members > 5 AND (md.production_year > 2000 OR md.production_year IS NULL))
GROUP BY 
    md.title, 
    md.production_year, 
    md.keywords, 
    md.unique_cast_members, 
    md.unique_companies
HAVING 
    SUM(CASE WHEN md.unique_cast_members IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    md.production_year DESC, 
    md.unique_cast_members DESC 
LIMIT 10;

This SQL query uses:
1. Common Table Expressions (CTEs) to break down the logic into manageable pieces.
2. Outer joins to handle possible NULL values.
3. Window functions for ranking movies by year of production.
4. Aggregation to summarize related data like keywords and cast members.
5. Conditional logic with CASE statements to categorize results.
6. Rich filtering logic with complicated predicates on the final results.
