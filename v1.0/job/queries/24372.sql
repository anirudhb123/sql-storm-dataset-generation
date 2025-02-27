
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(cc.nr_order), 0) AS total_cast_members,
        COUNT(DISTINCT mc.company_id) AS total_production_companies
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cc ON mt.id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(c.nr_order), 0) + mh.total_cast_members AS total_cast_members,
        COUNT(DISTINCT mc2.company_id) + mh.total_production_companies AS total_production_companies
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = m.episode_of_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_companies mc2 ON m.id = mc2.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, mh.total_cast_members, mh.total_production_companies
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.total_cast_members,
        mh.total_production_companies,
        RANK() OVER (ORDER BY mh.total_cast_members DESC, mh.total_production_companies ASC) AS rn
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.production_year IS NOT NULL 
        AND mh.production_year > 2000
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast_members,
    rm.total_production_companies,
    CASE 
        WHEN rm.total_cast_members > 10 THEN 'Large Cast'
        WHEN rm.total_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM company_name cn 
     JOIN movie_companies mct ON cn.id = mct.company_id 
     WHERE mct.movie_id = rm.movie_id) AS production_companies,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.movie_id 
       AND (mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Box Office%') 
            OR mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Rating%'))
    ) AS relevant_info_count
FROM 
    ranked_movies rm
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.total_cast_members DESC, rm.total_production_companies ASC;
