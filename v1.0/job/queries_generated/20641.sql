WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(mt2.title, 'N/A') AS linked_title,
        COALESCE(mt2.production_year, 'N/A') AS linked_year,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(mt2.title, 'N/A') AS linked_title,
        COALESCE(mt2.production_year, 'N/A') AS linked_year,
        level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.id = mh.movie_id
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
), 
MovieStatistics AS (
    SELECT 
        mh.title AS title,
        mh.production_year,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS total_movies,
        COUNT(DISTINCT mh.linked_title) AS linked_titles_count,
        MAX(mh.level) AS max_level
    FROM 
        MovieHierarchy mh
    GROUP BY 
        mh.title, mh.production_year
), 
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_movies,
        linked_titles_count,
        max_level,
        ROW_NUMBER() OVER (ORDER BY total_movies DESC, max_level DESC) AS ranking
    FROM 
        MovieStatistics
)

SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.total_movies AS Total_Movies,
    tm.linked_titles_count AS Linked_Titles,
    tm.max_level AS Max_Linked_Level
FROM 
    TopMovies tm
WHERE 
    tm.ranking <= 10
    AND (tm.linked_titles_count IS NOT NULL OR tm.linked_titles_count > 0)
    AND (tm.production_year IS NOT NULL) 
ORDER BY 
    tm.production_year DESC;
