WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        year_rank,
        actors,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        keyword_count > 5 -- only movies with more than 5 keywords
),
YearlySummary AS (
    SELECT 
        production_year,
        COUNT(*) AS total_movies,
        COUNT(CASE WHEN year_rank <= 3 THEN 1 END) AS top_ranked_movies,
        STRING_AGG(movie_title, '; ') AS all_movies
    FROM 
        FilteredMovies
    GROUP BY 
        production_year
),
FinalOutput AS (
    SELECT 
        fy.production_year,
        fy.total_movies,
        fy.top_ranked_movies,
        fy.all_movies,
        CASE 
            WHEN fy.total_movies > 0 THEN ROUND(100.0 * fy.top_ranked_movies / fy.total_movies, 2)
            ELSE NULL
        END AS top_rank_percentage
    FROM 
        YearlySummary fy
    WHERE 
        fy.production_year BETWEEN 1990 AND 2020
)

SELECT 
    fo.production_year,
    fo.total_movies,
    fo.top_ranked_movies,
    fo.all_movies,
    COALESCE(fo.top_rank_percentage, 0) AS top_rank_percentage,
    CASE 
        WHEN fo.top_rank_percentage IS NOT NULL AND fo.top_rank_percentage >= 50 THEN 'Dominance'
        WHEN fo.top_rank_percentage IS NULL THEN 'No data'
        ELSE 'Struggle'
    END AS performance_category
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC;

This SQL query performs a series of operations to benchmark movie performance by year, including filtering based on keyword counts, running aggregate functions, employing window functions for ranking, and categorizing performance results. It also makes extensive use of Common Table Expressions (CTEs) for clarity and organization. The final output includes calculated percentages and qualitative performance categories based on the calculated data.
