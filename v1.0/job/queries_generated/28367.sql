WITH name_counts AS (
    SELECT 
        n.id as name_id,
        n.name AS full_name,
        n.gender,
        COUNT(ci.movie_id) AS role_count
    FROM 
        name n
    LEFT JOIN 
        cast_info ci ON n.id = ci.person_id
    GROUP BY 
        n.id, n.name, n.gender
),

movie_info_aggregated AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(mi.id) AS info_types_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        AVG(mi.id) AS avg_info_type_id -- just for benchmarking
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
)

SELECT 
    nc.full_name,
    nc.gender,
    nc.role_count,
    mia.title,
    mia.info_types_count,
    mia.keyword_count,
    mia.avg_info_type_id
FROM 
    name_counts nc
JOIN 
    cast_info ci ON nc.name_id = ci.person_id
JOIN 
    movie_info_aggregated mia ON ci.movie_id = mia.movie_id
WHERE 
    nc.role_count > 0
ORDER BY 
    nc.role_count DESC, mia.keyword_count DESC
LIMIT 10;
