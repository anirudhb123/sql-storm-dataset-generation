WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rank
    FROM MovieHierarchy mh
), 
MovieRoles AS (
    SELECT 
        ci.movie_id,
        ct.kind AS role_type,
        COUNT(*) AS num_roles
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.movie_id, ct.kind
),
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        COALESCE(mr.role_type, 'Unknown') AS role_type,
        COALESCE(mr.num_roles, 0) AS num_roles
    FROM RankedMovies rm
    LEFT JOIN MovieRoles mr ON rm.movie_id = mr.movie_id
)

SELECT 
    cd.title,
    cd.production_year,
    cd.role_type,
    cd.num_roles,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = cd.movie_id) AS total_cast,
    (SELECT COUNT(DISTINCT mci.company_id) FROM movie_companies mci WHERE mci.movie_id = cd.movie_id) AS total_companies
FROM CombinedData cd
WHERE cd.production_year BETWEEN 1990 AND 2020
AND (cd.role_type IS NULL OR cd.role_type != 'Unknown' OR cd.num_roles > 2)
ORDER BY cd.production_year ASC, cd.num_roles DESC
LIMIT 50;
