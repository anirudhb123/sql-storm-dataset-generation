WITH Recursive MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(cc.person_id, 0) AS cast_member_id,
        COALESCE(an.name, 'Unknown') AS actor_name,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cc ON mt.id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.person_id = an.person_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(cc.person_id, 0),
        COALESCE(an.name, 'Unknown') AS actor_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.person_id = an.person_id
    WHERE 
        mh.level < 5  -- limiting levels to avoid infinite recursion
),
AggregatedInfo AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT mh.cast_member_id) AS total_cast_members,
        AVG(mh.production_year) OVER () AS avg_produced_year,
        STRING_AGG(DISTINCT mh.actor_name, ', ') AS actor_list
    FROM 
        MovieHierarchy mh
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
),
RankedMovies AS (
    SELECT 
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.total_cast_members DESC) AS rn
    FROM 
        AggregatedInfo a
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.total_cast_members,
    rm.actor_list,
    CASE 
        WHEN rm.production_year < 1980 THEN 'Classic'
        WHEN rm.production_year BETWEEN 1980 AND 2000 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era_category,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rm.movie_id AND mc.company_id IS NULL) AS null_company_count
FROM 
    RankedMovies rm
WHERE 
    (rm.total_cast_members > 1 OR rm.actor_list LIKE '%_Smith%')
    AND rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.total_cast_members DESC;

