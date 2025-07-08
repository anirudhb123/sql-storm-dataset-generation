
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
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
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),

cast_with_roles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        MAX(CASE WHEN c.id IS NOT NULL THEN c.name END) AS primary_actor
    FROM
        cast_info ci
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        ci.movie_id
),

movie_keywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),

complex_query AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cwr.role_count, 0) AS total_roles,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN mh.production_year > 2020 THEN 'Recent'
            WHEN mh.production_year BETWEEN 2010 AND 2020 THEN 'Moderate'
            ELSE 'Old'
        END AS age_category,
        CASE
            WHEN cwr.primary_actor IS NULL THEN 'Unknown Actor'
            ELSE cwr.primary_actor
        END AS leading_actor
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
    LEFT JOIN
        movie_keywords mk ON mh.movie_id = mk.movie_id
)

SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY age_category ORDER BY production_year DESC) AS row_num
FROM
    complex_query
WHERE
    total_roles > 2 
    AND (keywords IS NULL OR keywords LIKE '%action%')
ORDER BY
    production_year DESC, title;
