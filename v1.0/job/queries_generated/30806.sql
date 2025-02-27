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
        mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
notable_persons AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        c.movie_id,
        COUNT(ci.role_id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        at.production_year = 2023
    GROUP BY 
        a.name, a.id, ci.movie_id
    HAVING 
        COUNT(ci.role_id) > 1
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        STRING_AGG(DISTINCT np.actor_name, ', ') AS notable_actors,
        COUNT(DISTINCT mw.keyword_id) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mw ON mh.movie_id = mw.movie_id
    LEFT JOIN 
        notable_persons np ON mh.movie_id = np.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.kind_id
),
ranked_movies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.kind_id ORDER BY md.keyword_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.notable_actors,
    CASE 
        WHEN rm.keyword_count > 10 THEN 'High'
        WHEN rm.keyword_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Low'
    END AS keyword_category,
    COALESCE(cn.name, 'Unknown') AS company_name
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.kind_id, rm.rank;
