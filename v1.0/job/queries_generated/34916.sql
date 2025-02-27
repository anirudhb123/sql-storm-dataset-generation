WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS text) AS parent_title,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title AS mt
    JOIN 
        MovieHierarchy AS mh ON mt.episode_of_id = mh.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_title,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.parent_title ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy AS mh
    WHERE 
        mh.level <= 3
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.parent_title,
    COALESCE(ci.company_count, 0) AS company_count,
    ci.company_name,
    ci.company_type,
    rm.rank
FROM 
    RankedMovies AS rm
LEFT JOIN 
    CompanyInfo AS ci ON rm.movie_id = ci.movie_id
WHERE 
    (rm.production_year > 2000 OR rm.rank < 3)
ORDER BY 
    rm.level, rm.rank;

