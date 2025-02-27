WITH AnnualMovieStats AS (
    SELECT 
        YEAR(t.production_year) AS Year,
        COUNT(DISTINCT t.id) AS TotalMovies,
        COUNT(DISTINCT ci.person_id) AS TotalActors,
        AVG(character_count) AS AvgTitleLength
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            AVG(LENGTH(title)) AS character_count
        FROM 
            aka_title
        GROUP BY 
            movie_id
    ) AS title_lengths ON title_lengths.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        Year
),
RankedMovies AS (
    SELECT 
        Year,
        TotalMovies,
        TotalActors,
        AvgTitleLength,
        RANK() OVER (ORDER BY TotalMovies DESC) AS MovieRank
    FROM 
        AnnualMovieStats
),
TopYears AS (
    SELECT 
        Year,
        TotalMovies,
        TotalActors,
        AvgTitleLength
    FROM 
        RankedMovies
    WHERE 
        MovieRank <= 5
)
SELECT 
    Ty.Year,
    Ty.TotalMovies,
    Ty.TotalActors,
    Ty.AvgTitleLength,
    COALESCE(Ty.TotalActors / NULLIF(Ty.TotalMovies, 0), 0) AS ActorPerMovieRatio,
    CASE 
        WHEN Ty.AvgTitleLength > 30 THEN 'Long Titles'
        WHEN Ty.AvgTitleLength BETWEEN 15 AND 30 THEN 'Moderate Titles'
        ELSE 'Short Titles'
    END AS TitleLengthCategory
FROM 
    TopYears Ty
JOIN 
    (SELECT DISTINCT movie_id 
     FROM movie_keyword 
     WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')) AS ActionMovies 
ON 
    ActionMovies.movie_id IN (SELECT id FROM aka_title WHERE production_year = Ty.Year)
ORDER BY 
    Ty.Year DESC;

-- This complex query performs several actions:
-- 1. It collects annual movie statistics including the total number of movies,
--    total actors, and average title lengths by year.
-- 2. It ranks those years by total movies.
-- 3. It filters to the top 5 years based on movie releases.
-- 4. It calculates an actor-to-movie ratio and categorizes titles based on length.
-- 5. It joins with titles containing the 'action' keyword ensuring only relevant movies are analyzed.
