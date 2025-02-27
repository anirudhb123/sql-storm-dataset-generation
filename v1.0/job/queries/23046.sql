WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rankWithinYear,
        COUNT(*) OVER (PARTITION BY t.production_year) AS totalMoviesInYear
    FROM 
        aka_title t
),
FilteredMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN rm.rankWithinYear IS NULL THEN 'No Rank'
            WHEN rm.rankWithinYear <= 5 THEN 'Top 5'
            ELSE 'Others'
        END AS rank_category
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(*) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
MovieTitlesWithCompanies AS (
    SELECT 
        fm.*,
        COALESCE(mc.total_companies, 0) AS company_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieCompanies mc ON fm.movie_id = mc.movie_id
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS aggregated_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    mt.rank_category,
    mt.company_count,
    tk.aggregated_keywords,
    CASE 
        WHEN mt.company_count > 10 THEN 'High'
        WHEN mt.company_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS company_count_category
FROM 
    MovieTitlesWithCompanies mt
LEFT JOIN 
    TopKeywords tk ON mt.movie_id = tk.movie_id
WHERE 
    mt.totalMoviesInYear > 10
ORDER BY 
    mt.production_year DESC, 
    mt.rankWithinYear ASC 
LIMIT 50;
