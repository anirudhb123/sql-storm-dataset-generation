WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        CAST(1 AS INTEGER) AS level,
        t.episode_of_id
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.level + 1,
        t.episode_of_id
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank,
        COUNT(cm.company_id) AS company_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_companies cm ON mh.movie_id = cm.movie_id
    WHERE 
        mh.level <= 3
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),
CastInfoAnalysis AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count,
        AVG(ci.nr_order) AS average_order,
        STRING_AGG(DISTINCT CONCAT(an.name, ' (', rt.role, ')'), ', ') AS cast_details
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
FinalOutput AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.level,
        rm.title_rank,
        COALESCE(ca.unique_cast_count, 0) AS unique_cast_count,
        COALESCE(ca.average_order, 0.0) AS average_order,
        COALESCE(ca.cast_details, 'No Cast') AS cast_details,
        rm.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastInfoAnalysis ca ON rm.movie_id = ca.movie_id
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.level,
    fo.title_rank,
    fo.unique_cast_count,
    fo.average_order,
    fo.cast_details,
    CASE 
        WHEN fo.company_count > 0 THEN 'Produced'
        ELSE 'Not Produced' 
    END AS production_status
FROM 
    FinalOutput fo
WHERE 
    fo.unique_cast_count >= 2
    AND fo.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fo.production_year DESC, 
    fo.level, 
    fo.title_rank;
