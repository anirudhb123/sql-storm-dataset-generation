WITH RecursiveMovieYears AS (
    SELECT DISTINCT production_year
    FROM aka_title
    WHERE production_year IS NOT NULL
),
YearlyMovieCounts AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_id) AS total_movies
    FROM aka_title 
    GROUP BY production_year
),
StarCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS star_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieTitleInfo AS (
    SELECT 
        at.title,
        at.production_year,
        COALESCE(ymc.total_movies, 0) AS total_movies_previous_year,
        sc.star_count
    FROM aka_title at
    LEFT JOIN YearlyMovieCounts ymc ON at.production_year = ymc.production_year + 1
    LEFT JOIN StarCounts sc ON at.movie_id = sc.movie_id
),
TitleWithKeywords AS (
    SELECT 
        mti.title,
        mti.production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM MovieTitleInfo mti
    JOIN movie_keyword mk ON mti.movie_id = mk.movie_id
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mti.title, mti.production_year
),
OrderOfTitles AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY star_count DESC NULLS LAST, title) AS rn
    FROM TitleWithKeywords
)

SELECT 
    oot.title,
    oot.production_year,
    oot.total_movies_previous_year,
    oot.star_count,
    oot.keywords,
    CASE 
        WHEN oot.star_count IS NULL THEN 'No stars'
        WHEN oot.keywords IS NULL THEN 'No keywords'
        ELSE 'Available'
    END AS availability_status
FROM OrderOfTitles oot
WHERE oot.rn <= 5
  AND (NOT EXISTS (SELECT 1 
                   FROM aka_name an 
                   WHERE an.person_id IN (SELECT person_id 
                                          FROM cast_info 
                                          WHERE movie_id = oot.movie_id))
       OR EXISTS (SELECT 1 
                   FROM movie_info mi 
                   WHERE mi.movie_id = oot.movie_id 
                     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')))
ORDER BY oot.production_year DESC, oot.star_count DESC;

This SQL query is intended for performance benchmarking and incorporates several complex SQL constructs including CTEs, outer joins, correlated subqueries, window functions, and various conditions. It aims to analyze movie titles in the database, pulling in details about production year, star counts, and keywords associated with each title while respecting various peculiar edge cases.
