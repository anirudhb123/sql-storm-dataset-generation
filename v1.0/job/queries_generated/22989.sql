WITH RecursiveRoleHierarchy AS (
    SELECT 
        rt.id AS role_id,
        rt.role AS role_name,
        rt.id AS parent_role_id,
        1 AS level
    FROM 
        role_type rt
    WHERE 
        rt.role IS NOT NULL

    UNION ALL

    SELECT 
        rt.id AS role_id,
        rt.role AS role_name,
        r.parent_role_id,
        r.level + 1
    FROM 
        role_type rt
    JOIN 
        RecursiveRoleHierarchy r ON rt.id = r.parent_role_id
)

, MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS production_companies,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
)

SELECT 
    ad.title AS movie_title,
    ad.production_year,
    ad.rank_by_cast,
    CASE 
        WHEN ad.total_cast > 10 THEN 'Large Cast'
        WHEN ad.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT AVG(total_cast) 
     FROM MovieDetails) AS average_cast_size,
    (SELECT COUNT(*) 
     FROM MovieDetails 
     WHERE rank_by_cast = 1) AS total_top_movies,
    COALESCE((SELECT COUNT(*) 
              FROM alias a 
              WHERE a.name = 'Mysterious Alice'), 0) AS alias_references
FROM 
    MovieDetails ad
WHERE 
    ad.rank_by_cast <= 3
ORDER BY 
    ad.production_year DESC, ad.rank_by_cast;
