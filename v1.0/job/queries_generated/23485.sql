WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
, title_keywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
)
, ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        tk.keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        title_keywords tk ON mh.movie_id = tk.movie_id
)
SELECT 
    rm.rank,
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(NULLIF(rm.keywords, ''), 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = rm.movie_id AND ci.note IS NULL) AS uncredited_actors,
    (SELECT COUNT(DISTINCT ci.person_id) FROM cast_info ci WHERE ci.movie_id = rm.movie_id) AS total_casters,
    CASE 
        WHEN rm.production_year IS NOT NULL THEN 
            CASE 
                WHEN rm.production_year > 2000 THEN 'Modern'
                WHEN rm.production_year BETWEEN 1980 AND 2000 THEN 'Classic'
                ELSE 'Vintage'
            END
        ELSE 'Unknown Year'
    END AS era_category
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, rm.rank;

-- This query provided a hierarchy of movies linked by their relations,
-- extracting keywords associated with each movie while employing CTEs, window functions,
-- conditional logic for era categorization, and handling potential NULL values gracefully.
