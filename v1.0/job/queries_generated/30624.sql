WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = m.episode_of_id
    WHERE 
        m.episode_of_id IS NOT NULL
),

MovieStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(mk_keyword_count) AS avg_keywords
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS mk_keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) mk ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),

DetailedMovieStats AS (
    SELECT 
        mhs.movie_id,
        mhs.movie_title,
        mhs.production_year,
        mhs.cast_count,
        mhs.company_count,
        mhs.avg_keywords,
        RANK() OVER (ORDER BY mhs.production_year DESC) AS production_year_rank
    FROM 
        MovieStats mhs
),

Result AS (
    SELECT 
        dms.movie_id,
        dms.movie_title,
        dms.production_year,
        dms.cast_count,
        dms.company_count,
        dms.avg_keywords,
        dms.production_year_rank,
        COALESCE(mn.name, 'Unknown') AS main_actor
    FROM 
        DetailedMovieStats dms
    LEFT JOIN 
        cast_info ci ON dms.movie_id = ci.movie_id AND ci.nr_order = 1
    LEFT JOIN 
        aka_name mn ON ci.person_id = mn.person_id
)

SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.cast_count,
    r.company_count,
    r.avg_keywords,
    r.production_year_rank,
    CASE 
        WHEN r.main_actor IS NULL THEN 'N/A'
        ELSE r.main_actor
    END AS main_actor
FROM 
    Result r
WHERE 
    r.company_count > 2 OR r.avg_keywords > 5
ORDER BY 
    r.production_year_rank ASC, r.cast_count DESC
LIMIT 100;
