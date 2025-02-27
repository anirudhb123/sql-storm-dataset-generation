WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(SUM(mc.note IS NOT NULL)::int, 0) AS company_count,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM
        aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE 
        mt.production_year >= 2000 
    GROUP BY 
        mt.id, mt.title

    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.company_count,
        mh.cast_names
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
),
LatestMovies AS (
    SELECT 
        at.id AS movie_id, 
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.company_count,
    mh.cast_names,
    lm.production_year
FROM 
    MovieHierarchy mh
JOIN LatestMovies lm ON mh.movie_id = lm.movie_id
WHERE 
    lm.rn = 1
ORDER BY 
    mh.production_year DESC, mh.company_count DESC
FETCH FIRST 10 ROWS ONLY;

-- Including NULL logic and more complex predicates
SELECT 
    mt.title,
    CASE 
        WHEN mt.production_year IS NULL THEN 'Unknown Year'
        ELSE mt.production_year::TEXT
    END AS production_year,
    CAST(ROUND(AVG(rl.rating), 2) AS TEXT) AS avg_rating
FROM 
    aka_title mt
LEFT JOIN (
    SELECT 
        m.movie_id,
        r.rating
    FROM 
        movie_info m
    JOIN info_type it ON m.info_type_id = it.id
    JOIN (SELECT movie_id, AVG(rating) AS rating FROM movie_info GROUP BY movie_id) AS r ON m.movie_id = r.movie_id
    WHERE 
        it.info = 'Rating'
) rl ON mt.id = rl.movie_id
WHERE 
    mt.title IS NOT NULL -- Demonstrating NULL filtering in predicates
GROUP BY 
    mt.title, mt.production_year
HAVING 
    ROUND(AVG(rl.rating), 2) IS NOT NULL
ORDER BY 
    mt.production_year DESC;
