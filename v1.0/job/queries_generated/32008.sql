WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_stats AS (
    SELECT 
        CAST(COUNT(c.id) AS INTEGER) AS total_cast,
        mt.id AS movie_id,
        mt.title,
        mt.production_year
    FROM 
        cast_info c
    JOIN 
        aka_title mt ON c.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

yearly_movie_count AS (
    SELECT 
        production_year,
        COUNT(id) AS movie_count
    FROM 
        aka_title
    GROUP BY 
        production_year
    ORDER BY 
        production_year DESC
),

business_insights AS (
    SELECT 
        cmt.movie_id,
        cm.name AS company_name,
        cmt.note,
        ROW_NUMBER() OVER (PARTITION BY cmt.movie_id ORDER BY cm.name) AS company_rank
    FROM 
        movie_companies cmt
    JOIN 
        company_name cm ON cmt.company_id = cm.id
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    yc.movie_count AS total_movies_per_year,
    bi.company_name AS production_company
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    yearly_movie_count yc ON mh.production_year = yc.production_year
LEFT JOIN 
    business_insights bi ON mh.movie_id = bi.movie_id
WHERE 
    bi.company_rank = 1
ORDER BY 
    mh.production_year DESC, mh.title;
