WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.title,
        m.id AS movie_id,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL 
    
    UNION ALL
    
    SELECT
        e.title,
        e.id AS movie_id,
        e.production_year,
        h.level + 1
    FROM
        aka_title e
    INNER JOIN
        movie_hierarchy h ON e.episode_of_id = h.movie_id 
),
company_movie_info AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_movies
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, c.name, ct.kind
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
final_report AS (
    SELECT
        mh.title,
        mh.production_year,
        cm.company_name,
        cm.company_type,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mh.level
    FROM
        movie_hierarchy mh
    LEFT JOIN
        company_movie_info cm ON mh.movie_id = cm.movie_id
    LEFT JOIN
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT
    fr.title,
    fr.production_year,
    fr.company_name,
    fr.company_type,
    fr.keywords,
    fr.level,
    ROW_NUMBER() OVER (PARTITION BY fr.production_year ORDER BY fr.level DESC) AS movie_rank
FROM
    final_report fr
WHERE
    fr.production_year >= 2000
ORDER BY
    fr.production_year DESC,
    fr.level ASC;