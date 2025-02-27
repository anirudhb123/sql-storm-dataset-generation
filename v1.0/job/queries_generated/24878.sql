WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_index,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        lm.id,
        lm.title,
        lm.production_year,
        lm.imdb_index,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS lm ON ml.linked_movie_id = lm.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5  -- limit recursion to avoid infinite loops
),

-- CTE to aggregate movie details
aggregate_movie_info AS (
    SELECT
        mh.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        MAX(m.production_year) AS latest_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        SUM(COALESCE(ci.nr_order, 0)) AS total_order
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        movie_companies AS mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name AS c ON ci.person_id = c.person_id
    GROUP BY 
        mh.movie_id
),

-- CTE for calculating ratings through the following
ranked_movies AS (
    SELECT 
        ami.*,
        ROW_NUMBER() OVER (PARTITION BY ami.latest_year ORDER BY ami.keyword_count DESC) AS ranking,
        CASE 
            WHEN ami.company_count > 10 THEN 'High Production'
            ELSE 'Low Production'
        END AS production_level
    FROM 
        aggregate_movie_info ami
    WHERE 
        ami.latest_year IS NOT NULL
)

-- Final selection with outer joins and complicated predicates
SELECT 
    rm.movie_id,
    rm.title,
    rm.latest_year,
    rm.ranking,
    rm.production_level,
    (SELECT AVG(info_type_id) FROM movie_info WHERE movie_id = rm.movie_id) AS avg_info_type,
    COALESCE(rm.cast_names, 'No Cast Info') AS cast_names,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) < 5 THEN 'Fewer Companies'
        ELSE 'Many Companies'
    END AS company_density
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.ranking <= 10  -- Top 10 movies
    AND rm.production_year > 2000 
  AND (NOT EXISTS (SELECT 1 FROM movie_info WHERE movie_id = rm.movie_id AND info_type_id IS NULL) 
       OR EXISTS (SELECT 1 FROM movie_info WHERE movie_id = rm.movie_id AND note IS NOT NULL))
ORDER BY 
    rm.latest_year DESC,
    rm.ranking ASC;
