WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS title,
        mt.production_year,
        1 AS depth,
        ARRAY[mt.id] AS hierarchy_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1,
        mh.hierarchy_path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        NOT (ml.linked_movie_id = ANY(mh.hierarchy_path))
),
CastRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        MAX(r.role) AS primary_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.movie_id
),
MovieGenres AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
),
FinalOutput AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(c.num_actors, 0) AS num_actors,
        COALESCE(mg.genres, 'Unknown') AS genres,
        mh.depth,
        (SELECT 
            AVG(star_rating) 
        FROM 
            movie_info mi 
        WHERE 
            mi.movie_id = mh.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
        ) AS avg_rating
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastRoles c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        MovieGenres mg ON mh.movie_id = mg.movie_id
    WHERE 
        mh.production_year > 2000 
        AND (mh.depth = 1 OR c.num_actors > 5)
)
SELECT 
    *,
    CASE
        WHEN avg_rating IS NULL THEN 'No Rating Available'
        ELSE avg_rating::text
    END AS rating_display
FROM 
    FinalOutput
WHERE 
    num_actors > 0
ORDER BY 
    production_year DESC, title ASC
LIMIT 100 OFFSET 0;

This SQL query generates a comprehensive report on movies produced after 2000, leveraging recursive common table expressions (CTEs) to establish movie linkage, counting actors in each movie, aggregating genres, and calculating average ratings—all while taking into account various corner cases like NULL values and unusual join conditions. It employs string aggregation, outer joins, and subqueries to create a rich dataset ready for performance benchmarking.
