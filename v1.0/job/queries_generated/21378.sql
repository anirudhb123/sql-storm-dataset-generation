WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE mh.level < 5
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles
    FROM cast_info ci
    GROUP BY ci.person_id, ci.movie_id
),
CastCount AS (
    SELECT 
        movie_id,
        COUNT(*) AS total_cast
    FROM cast_info
    GROUP BY movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(castCount.total_cast, 0) AS total_cast,
        COALESCE(pr.distinct_roles, 0) AS distinct_roles
    FROM MovieHierarchy mh
    LEFT JOIN CastCount castCount ON mh.movie_id = castCount.movie_id
    LEFT JOIN PersonRoles pr ON mh.movie_id = pr.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.distinct_roles,
    CASE 
        WHEN md.total_cast > 10 AND md.distinct_roles < 2 THEN 'Underrated'
        WHEN md.total_cast BETWEEN 5 AND 10 AND md.distinct_roles > 2 THEN 'Cult Classic'
        WHEN md.production_year < 2000 THEN 'Classic Movie'
        ELSE 'Modern Film'
    END AS classification,
    COUNT(DISTINCT ci.person_id) AS contributing_persons,
    STRING_AGG(DISTINCT ak.name, ', ') AS known_aliases
FROM MovieDetails md
LEFT JOIN cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
GROUP BY md.movie_id, md.title, md.production_year, md.total_cast, md.distinct_roles
HAVING COUNT(DISTINCT ci.person_id) > 2
ORDER BY md.production_year DESC, total_cast DESC;
