WITH RECURSIVE MovieRanks AS (
    SELECT 
        ct.id AS movie_id,
        ct.title AS title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY ct.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title ct
    LEFT JOIN 
        cast_info ci ON ct.movie_id = ci.movie_id
    GROUP BY 
        ct.id, ct.title, ct.production_year
),
RecentMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(COUNT(mk.keyword_id), 0) AS keyword_count,
        COALESCE(SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS has_trivia
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info pi ON a.movie_id = pi.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
HighRankedMovies AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.cast_count,
        mr.rank,
        rm.keyword_count,
        rm.has_trivia
    FROM 
        MovieRanks mr
    JOIN 
        RecentMovies rm ON mr.movie_id = rm.movie_id
    WHERE 
        mr.rank <= 5
)
SELECT 
    hr.movie_id,
    hr.title,
    hr.cast_count,
    hr.keyword_count,
    CASE 
        WHEN hr.has_trivia > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_trivia
FROM 
    HighRankedMovies hr
ORDER BY 
    hr.production_year DESC, hr.cast_count DESC;
This SQL query consists of several parts:

1. **Recursive CTE (MovieRanks)**: Calculates the rank of movies based on the number of distinct cast members for each production year.
2. **RecentMovies CTE**: Retrieves movies from 2000 onwards along with their count of associated keywords and trivia information.
3. **Join and filtering**: Combines results from both CTEs to filter for the top 5 movies based on their rank while also gathering keyword count and trivia presence.
4. **Final SELECT**: Outputs relevant data including a formatted trivia indicator.

This query can serve as a robust benchmark by demonstrating multiple SQL constructs intertwined for performance evaluation.
