WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        NULL::text AS parent_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.title AS parent_title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rnk
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.depth = 1
    GROUP BY 
        m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
    ORDER BY 
        m.production_year DESC
),
complete_movie_info AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(mci.info, 'No additional info') AS info,
        COALESCE(CAST(SUM(CASE WHEN mt.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS integer), 0) AS movie_company_count
    FROM 
        top_movies t
    LEFT JOIN 
        movie_info mci ON t.title = mci.info AND t.production_year = mci.movie_id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        kind_type kt ON mc.company_type_id = kt.id
    WHERE 
        kt.kind IS NULL OR kt.kind NOT IN ('Distributor')
    GROUP BY 
        t.title, t.production_year, mci.info
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1
)
SELECT 
    cmi.title,
    cmi.production_year,
    cmi.info,
    cmi.movie_company_count,
    CASE 
        WHEN cmi.movie_company_count > 10 THEN 'Major Production'
        ELSE 'Indie Film'
    END AS film_type,
    ROW_NUMBER() OVER (ORDER BY cmi.production_year DESC) AS overall_rank
FROM 
    complete_movie_info cmi
WHERE 
    cmi.production_year >= (
        SELECT 
            MAX(production_year) 
        FROM 
            complete_movie_info
        WHERE 
            movie_company_count BETWEEN 3 AND 8
    )
ORDER BY 
    cmi.production_year DESC
LIMIT 50;
