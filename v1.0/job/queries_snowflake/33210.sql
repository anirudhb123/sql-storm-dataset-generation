
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.role_id IN (1, 2) THEN ci.person_id END) AS main_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
keyword_stats AS (
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
production_info AS (
    SELECT 
        co.name AS company_name,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        co.country_code = 'USA'
),
final_result AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        cs.total_cast,
        cs.main_cast,
        ks.keywords,
        pi.company_name
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_stats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_stats ks ON mh.movie_id = ks.movie_id
    LEFT JOIN 
        production_info pi ON mh.movie_id = pi.movie_id
)
SELECT 
    fr.movie_id,
    fr.movie_title,
    COALESCE(fr.total_cast, 0) AS total_cast,
    COALESCE(fr.main_cast, 0) AS main_cast,
    COALESCE(fr.keywords, 'None') AS keywords,
    COALESCE(fr.company_name, 'Independent') AS production_company
FROM 
    final_result fr
ORDER BY 
    fr.movie_title ASC;
