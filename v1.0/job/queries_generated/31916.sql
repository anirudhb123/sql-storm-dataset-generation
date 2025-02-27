WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all titles
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_movie_id
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    -- Recursive case: Get linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        title.title,
        title.production_year,
        mh.movie_id AS parent_movie_id
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title ON ml.linked_movie_id = title.id
)

SELECT 
    ti.title AS Movie_Title,
    ti.production_year AS Production_Year,
    ak.name AS Actor_Name,
    rt.role AS Actor_Role,
    COUNT(DISTINCT mc.company_id) AS num_production_companies,
    AVG(years_of_experience.years) AS Average_Experience
FROM
    title ti
JOIN 
    cast_info ci ON ti.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_companies mc ON ti.id = mc.movie_id 
JOIN 
    (SELECT 
        person_id,
        EXTRACT(YEAR FROM CURRENT_DATE) - MIN(EXTRACT(YEAR FROM pi.info)) AS years 
    FROM 
        person_info pi
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Experience')
    GROUP BY 
        person_id) years_of_experience ON ak.person_id = years_of_experience.person_id
WHERE 
    ti.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
    AND rt.role IS NOT NULL
GROUP BY 
    ti.title, ti.production_year, ak.name, rt.role
ORDER BY 
    Production_Year DESC, Movie_Title ASC
FETCH FIRST 100 ROWS ONLY;

-- Additionally, analyze performance based on execution plan and timing.

