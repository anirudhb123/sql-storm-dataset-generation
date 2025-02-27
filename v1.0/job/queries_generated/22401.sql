WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Only movies
    
    UNION ALL
    
    SELECT
        linked.linked_movie_id,
        linked.title,
        linked.production_year,
        mh.movie_id
    FROM
        movie_link linked
    JOIN 
        movie_hierarchy mh ON linked.movie_id = mh.movie_id
),
cte_aka_names AS (
    SELECT 
        ak.person_id,
        ak.name AS aka_name,
        RANK() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS rank
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
),
latest_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.note,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order DESC) AS rn
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        at.production_year = (SELECT MAX(production_year) FROM aka_title)
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(GROUP_CONCAT(aka.aka_name ORDER BY aka.rank), 'No Names') AS aka_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cte_aka_names aka ON aka.person_id IN (
            SELECT 
                DISTINCT ci.person_id
            FROM 
                latest_cast ci
            WHERE 
                ci.movie_id = mh.movie_id AND ci.rn = 1
        )
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    fmv.title,
    fmv.production_year,
    fmv.aka_names,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mf.info IS NULL THEN 1 ELSE 0 END) AS null_info_count
FROM 
    filtered_movies fmv
LEFT JOIN 
    movie_companies mc ON mc.movie_id = fmv.movie_id
LEFT JOIN 
    movie_info mf ON mf.movie_id = fmv.movie_id AND mf.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE '%budget%'
    )
GROUP BY 
    fmv.title, fmv.production_year, fmv.aka_names
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    fmv.production_year DESC,
    fmv.title ASC;
