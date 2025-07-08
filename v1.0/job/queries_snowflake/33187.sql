
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(mc.company_id), 0) AS total_companies,
        1 AS depth
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY
        m.id, m.title, m.production_year
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(mc.company_id), 0) + mh.total_companies AS total_companies,
        mh.depth + 1
    FROM
        aka_title m
    INNER JOIN
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY
        m.id, m.title, m.production_year, mh.total_companies, mh.depth
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS num_cast_members,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.total_companies,
    cs.num_cast_members,
    cs.cast_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.total_companies DESC) AS rank_by_company_count,
    RANK() OVER (ORDER BY mh.production_year DESC, mh.total_companies DESC) AS global_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
WHERE 
    mh.production_year >= 2000
    AND mh.total_companies > 1
    AND EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = mh.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    )
ORDER BY 
    mh.production_year DESC, 
    mh.total_companies DESC;
