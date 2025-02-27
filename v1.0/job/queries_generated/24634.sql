WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(DISTINCT mk.keyword) OVER (PARTITION BY mt.movie_id) AS keyword_count,
        MAX(CASE WHEN ko.info = 'Oscar' THEN 1 ELSE 0 END) OVER (PARTITION BY mt.movie_id) AS has_oscar
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info ko ON mt.movie_id = ko.movie_id AND ko.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
)

SELECT 
    r.title AS Movie_Title,
    r.production_year AS Year,
    r.year_rank AS Rank_within_Year,
    COALESCE(k.keyword_count, 0) AS Unique_Keyword_Count,
    CASE 
        WHEN r.has_oscar = 1 THEN 'Yes'
        ELSE 'No' 
    END AS Awarded
FROM 
    RankedMovies r
LEFT JOIN 
    (SELECT movie_id, COUNT(DISTINCT keyword_id) AS keyword_count
     FROM movie_keyword
     GROUP BY movie_id) k ON r.movie_id = k.movie_id
WHERE 
    (r.production_year IS NOT NULL AND r.production_year > 2000) 
    AND (r.title LIKE '%Avengers%' OR r.title LIKE '%Star Wars%')
ORDER BY 
    r.production_year DESC, k.keyword_count DESC
LIMIT 20;

-- Testing outer joins and NULL logic 
SELECT 
    cn.id AS Company_ID,
    cn.name AS Company_Name,
    COUNT(mc.movie_id) AS Number_of_Movies
FROM 
    company_name cn
LEFT JOIN 
    movie_companies mc ON cn.id = mc.company_id
GROUP BY 
    cn.id, cn.name
HAVING 
    COUNT(mc.movie_id) = 0 OR MAX(mc.note) IS NULL
ORDER BY 
    Company_Name ASC;

-- Using correlated subqueries
SELECT 
    p.id AS Person_ID,
    p.name AS Person_Name,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.person_id = p.id) AS Total_Roles
FROM 
    name p
WHERE 
    EXISTS (SELECT 1 
            FROM cast_info ci 
            WHERE ci.person_id = p.id AND ci.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year > 2010))
ORDER BY 
    Total_Roles DESC;

-- String expressions and complicated predicates 
SELECT 
    DISTINCT a.name,
    LEFT(a.name, 3) || RIGHT(a.name, 3) AS Name_Expression
FROM 
    aka_name a
WHERE 
    LENGTH(a.name) > 5 AND 
    (a.name LIKE '%son%' OR a.name LIKE '%berg%' OR a.name IS NULL)
ORDER BY 
    Name_Expression DESC;

-- Combine with an unusual set operation 
SELECT 
    title FROM (
        SELECT title FROM aka_title WHERE production_year < 2000
        INTERSECT
        SELECT title FROM aka_title WHERE kind_id = 1
        UNION
        SELECT title FROM aka_title WHERE title LIKE '%Jurassic%'
    ) AS CombinedTitles
ORDER BY 
    title;
