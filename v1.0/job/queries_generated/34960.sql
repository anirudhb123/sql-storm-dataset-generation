WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.title,
        mt.production_year,
        ml.linked_movie_id AS movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year,
    (SELECT COUNT(DISTINCT ci.person_id)
     FROM cast_info ci
     WHERE ci.movie_id = mh.movie_id) AS Actor_Count,
    (SELECT COUNT(DISTINCT k.keyword)
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = mh.movie_id) AS Keyword_Count,
    COALESCE(
        MAX(sg.salary), 
        0
    ) AS Max_Salary,
    STRING_AGG(DISTINCT cn.name, ', ') AS Company_Names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast c ON mh.movie_id = c.movie_id
LEFT JOIN 
    person_info pi ON c.subject_id = pi.person_id
LEFT JOIN 
    (SELECT 
         company_name.id,
         company_name.name,
         movie_companies.movie_id,
         company_type.kind AS company_type
     FROM 
         company_name
     JOIN 
         movie_companies ON company_name.id = movie_companies.company_id
     JOIN 
         company_type ON movie_companies.company_type_id = company_type.id
    ) cn ON mh.movie_id = cn.movie_id
LEFT JOIN 
    (SELECT 
         ci.person_role_id,
         SUM(pi.salary) AS salary
     FROM 
         cast_info ci
     JOIN 
         person_info pi ON ci.person_id = pi.person_id
     WHERE 
         pi.info_type_id = (SELECT id FROM info_type WHERE info = 'salary')
     GROUP BY 
         ci.person_role_id
    ) sg ON c.person_role_id = sg.person_role_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, Actor_Count DESC;
