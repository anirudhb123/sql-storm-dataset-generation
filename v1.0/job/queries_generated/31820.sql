WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start with root movies (no episodes)
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.path || et.id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id  -- Recursive join to find episodes
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No info available') AS info_detail,
        CASE 
            WHEN cc.kind IS NULL THEN 'Other' 
            ELSE cc.kind 
        END AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY mi.info_type_id) AS info_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_type cc ON mc.company_type_id = cc.id
),
FinalSelection AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ARRAY_AGG(DISTINCT mi.info_detail ORDER BY mi.info_rank) AS movie_info_details,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        MAX(mi.info_rank) AS max_info_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
Summary AS (
    SELECT 
        COUNT(*) AS total_movies,
        AVG(total_companies) AS avg_companies_per_movie,
        MAX(m.production_year) AS latest_year,
        MIN(m.production_year) AS earliest_year
    FROM 
        FinalSelection m
)
SELECT 
    s.total_movies,
    s.avg_companies_per_movie,
    s.latest_year,
    s.earliest_year,
    f.movie_id,
    f.title,
    f.production_year,
    f.movie_info_details
FROM 
    Summary s
JOIN 
    FinalSelection f ON f.total_companies > (SELECT AVG(total_companies) FROM FinalSelection)  -- Movies with above-average company count
ORDER BY 
    f.production_year DESC;
