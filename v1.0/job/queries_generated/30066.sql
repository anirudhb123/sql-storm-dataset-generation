WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_link AS ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
        
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
),
aggregated_info AS (
    SELECT 
        mh.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mh.movie_id
)
SELECT 
    a.title,
    a.production_year,
    a.total_cast,
    a.total_keywords,
    a.keywords_list,
    COALESCE(SUM(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') THEN 1 ELSE 0 END), 0) AS actor_birth_dates_count,
    RANK() OVER (ORDER BY a.total_cast DESC) AS cast_rank
FROM 
    aggregated_info AS a
LEFT JOIN 
    cast_info AS ci ON a.movie_id = ci.movie_id
LEFT JOIN 
    person_info AS pi ON ci.person_id = pi.person_id
WHERE 
    a.total_cast > 0
GROUP BY 
    a.movie_id, a.title, a.production_year, a.total_cast, a.total_keywords, a.keywords_list
ORDER BY 
    cast_rank, a.production_year DESC
LIMIT 50;

