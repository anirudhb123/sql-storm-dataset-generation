WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.production_year,
        depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id 
    WHERE 
        m.production_year > 2000
),
cast_info_with_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movies_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ci.total_cast,
        ci.roles,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count,
        CASE 
            WHEN (mh.production_year < 2010) THEN 'Classic'
            WHEN (mh.production_year BETWEEN 2010 AND 2015) THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info_with_roles ci ON mh.movie_id = ci.movie_id
),
final_benchmark AS (
    SELECT 
        mi.title,
        mi.production_year,
        mi.total_cast,
        COALESCE(mi.roles, 'No roles') AS roles,
        mi.keyword_count,
        mi.era,
        ROW_NUMBER() OVER (PARTITION BY mi.era ORDER BY mi.total_cast DESC) AS rank,
        RANK() OVER (ORDER BY mi.total_cast DESC) AS overall_rank
    FROM 
        movies_info mi
)
SELECT 
    fb.title,
    fb.production_year,
    fb.total_cast,
    fb.roles,
    fb.keyword_count,
    fb.era,
    fb.rank,
    fb.overall_rank
FROM 
    final_benchmark fb
WHERE 
    fb.total_cast IS NOT NULL 
ORDER BY 
    fb.era ASC, fb.rank ASC;
