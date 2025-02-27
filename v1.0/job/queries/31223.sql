WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.level + 1,
        CAST(CONCAT(mh.path, ' > ', mt.title) AS VARCHAR(255))
    FROM 
        aka_title mt
    INNER JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.path AS movie_hierarchy,
    rm.title AS movie_title,
    rm.production_year,
    cs.company_count,
    cs.company_names,
    coalesce(ct.cast_count, 0) AS cast_count
FROM 
    MovieHierarchy mh
JOIN 
    RankedMovies rm ON mh.movie_id = rm.id
LEFT JOIN 
    CompanyStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    CastStats ct ON mh.movie_id = ct.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020 
    AND (cs.company_count IS NULL OR cs.company_count > 1)
ORDER BY 
    rm.production_year DESC, mh.level, rm.title;
