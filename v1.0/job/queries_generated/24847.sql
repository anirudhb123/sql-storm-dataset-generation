WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        lt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

aggregated_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

distinct_persons AS (
    SELECT DISTINCT 
        ci.person_id,
        ak.name AS actor_name,
        ak.id AS aka_id
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.role_id IS NOT NULL
),

final_report AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ak.name AS leading_actor,
        ak.md5sum,
        COALESCE(dkp.keywords_list, 'No Keywords') AS keywords,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        distinct_persons ak ON mh.movie_id = ak.id
    LEFT JOIN 
        aggregated_keywords dkp ON mh.movie_id = dkp.movie_id
)

SELECT 
    fr.*,
    CASE 
        WHEN fr.year_rank <= 10 THEN 'Top 10 Movies of Year'
        ELSE 'Other Movies'
    END AS ranking_category
FROM 
    final_report fr
WHERE 
    fr.production_year IS NOT NULL
AND 
    fr.leading_actor IS NOT NULL
ORDER BY 
    fr.production_year DESC, 
    fr.title;
