WITH RECURSIVE RelatedMovies AS (
    SELECT m.id AS movie_id, mt.title, c.name AS company_name, mt.production_year,
           ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY m.production_year DESC) AS rn
    FROM aka_title mt
    JOIN movie_companies mc ON mc.movie_id = mt.id
    JOIN company_name c ON c.id = mc.company_id
    WHERE mc.note IS NOT NULL AND mt.kind_id IN (1, 2) -- Assume 1 is for feature films, 2 for documentaries
    AND mt.production_year >= 2000
    UNION ALL
    SELECT lm.movie_id, lm.title, lm.company_name, lm.production_year, lm.rn
    FROM RelatedMovies rm
    JOIN movie_link ml ON ml.movie_id = rm.movie_id
    JOIN aka_title lm ON ml.linked_movie_id = lm.id
    WHERE lm.production_year = rm.production_year AND rm.rn < 5 -- fetch related movies in the same year, limiting to top 5
),
CastWithRoles AS (
    SELECT p.id AS person_id, ak.name, c.movie_id, r.role AS person_role,
           COUNT(*) OVER (PARTITION BY p.id) AS role_count
    FROM aka_name ak
    JOIN cast_info c ON c.person_id = ak.person_id
    JOIN role_type r ON r.id = c.role_id
    WHERE ak.name IS NOT NULL
)
SELECT DISTINCT 
    rm.title AS Related_Movie_Title,
    rm.production_year AS Production_Year,
    cc.company_name AS Production_Company,
    cwr.name AS Actor_Name,
    cwr.person_role AS Role,
    COALESCE(cwr.role_count, 0) AS Role_Count,
    CASE 
        WHEN cwr.role_count > 5 THEN 'Multiple Roles'
        ELSE 'Single Role'
    END AS Role_Category
FROM RelatedMovies rm
LEFT JOIN CastWithRoles cwr ON cwr.movie_id = rm.movie_id
LEFT JOIN movie_info mi ON mi.movie_id = rm.movie_id AND mi.note IS NOT NULL
WHERE (rm.production_year, rm.production_year - 5) IN (
    SELECT DISTINCT production_year, production_year - 5
    FROM aka_title 
)
ORDER BY rm.production_year DESC, Related_Movie_Title ASC, Actor_Name DESC;
