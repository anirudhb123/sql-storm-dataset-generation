
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        m.kind_id,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.kind_id IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        CONCAT(m.title, ' - ', c.title) AS title,
        COALESCE(m.production_year + 1, 0) AS production_year,
        m.kind_id,
        mh.depth + 1
    FROM
        movie_link ml
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
        JOIN aka_title m ON ml.linked_movie_id = m.id
        JOIN aka_title c ON c.id = mh.movie_id
    WHERE
        mh.depth < 5
),

cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
        AVG(ci.nr_order) AS avg_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

movie_company_details AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

movie_tags AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.cast_with_notes,
    cs.avg_order,
    mcd.total_companies,
    mcd.company_names,
    mt.keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rank,
    COALESCE(mh.depth, 0) AS movie_depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_statistics cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_company_details mcd ON mh.movie_id = mcd.movie_id
LEFT JOIN 
    movie_tags mt ON mh.movie_id = mt.movie_id
WHERE 
    mh.production_year >= 2000 
AND 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC,
    mh.title;
