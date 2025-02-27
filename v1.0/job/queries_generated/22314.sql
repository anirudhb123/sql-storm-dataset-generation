WITH RecursiveMovieHierarchy AS (
    SELECT 
        m1.id AS movie_id,
        m1.title AS movie_title,
        1 AS level,
        CAST(m1.id AS STRING) AS path
    FROM title m1
    WHERE m1.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m2.id AS movie_id,
        m2.title AS movie_title,
        rmh.level + 1,
        CAST(rmh.path || ' -> ' || m2.id AS STRING) AS path
    FROM title m2
    JOIN movie_link ml ON ml.movie_id = rmh.movie_id
    JOIN title m3 ON ml.linked_movie_id = m3.id
    JOIN RecursiveMovieHierarchy rmh ON m3.id = rmh.movie_id
    WHERE m2.production_year < 2000
),

TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON k.id = mt.keyword_id
    GROUP BY mt.movie_id
),

PersonRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    GROUP BY ci.movie_id
),

MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        CASE WHEN mi.info IS NULL THEN 'Not Rated' ELSE mi.info END AS rating
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
),

FinalResults AS (
    SELECT 
        th.movie_id,
        th.movie_title,
        mh.level,
        mh.path,
        COALESCE(pk.keywords, 'No Keywords') AS keywords,
        COALESCE(pr.total_actors, 0) AS total_actors,
        COALESCE(pr.roles, 'Unknown Roles') AS roles,
        COALESCE(mr.rating, 'No Rating') AS rating
    FROM RecursiveMovieHierarchy mh
    JOIN TitleKeywords pk ON mh.movie_id = pk.movie_id
    LEFT JOIN PersonRoles pr ON mh.movie_id = pr.movie_id
    LEFT JOIN MovieRatings mr ON mh.movie_id = mr.movie_id
)

SELECT 
    fr.movie_id,
    fr.movie_title,
    fr.level,
    fr.path,
    fr.keywords,
    fr.total_actors,
    fr.roles,
    fr.rating
FROM FinalResults fr
WHERE fr.total_actors > 5
ORDER BY fr.level DESC, fr.movie_title ASC
LIMIT 100;
