
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
    WHERE 
        mh.depth < 3
),
keyword_data AS (
    SELECT 
        mk.movie_id, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
company_data AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    LISTAGG(DISTINCT kd.keyword, ', ') WITHIN GROUP (ORDER BY kd.keyword) AS keywords,
    cd.company_name,
    cd.company_count,
    mh.depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    keyword_data kd ON mh.movie_id = kd.movie_id AND kd.keyword_rank <= 3
LEFT JOIN 
    company_data cd ON mh.movie_id = cd.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cd.company_name, cd.company_count, mh.depth
HAVING 
    COUNT(cd.company_name) > 0 OR mh.depth = 1
ORDER BY 
    mh.production_year DESC, mh.title;
