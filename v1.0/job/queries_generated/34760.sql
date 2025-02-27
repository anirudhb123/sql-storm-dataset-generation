WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
-- Selecting required fields 
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    
    -- Aggregate function with filtering
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    
    -- Using Window function to rank titles by their total cast members
    RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS Cast_Rank,

    -- Extracting first part of the title using string manipulation
    SUBSTRING(m.title FROM 1 FOR 10) AS Short_Title,

    -- Concatenating movie title with its year
    CONCAT(m.title, ' (', m.production_year, ')') AS Full_Title,

    -- Checking for NULL values in Cast Info
    CASE 
        WHEN ci.note IS NULL THEN 'No Note'
        ELSE ci.note 
    END AS Cast_Note

FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
WHERE 
    m.production_year BETWEEN 2010 AND 2020
    AND ci.nr_order IS NOT NULL    
GROUP BY 
    m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    CAST_Rank, Full_Title;
