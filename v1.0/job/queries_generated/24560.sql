WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- only considering movies from the 21st century

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.depth < 5 -- limiting the depth of hierarchy to avoid excessive recursion
),

TopPerformers AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_notes
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 10 -- Only include performers with more than 10 movies
),

RankedTitles AS (
    SELECT 
        title.id,
        title.title,
        c1.kind_id,
        ROW_NUMBER() OVER (PARTITION BY c1.kind_id ORDER BY mt.production_year DESC, title.title ASC) AS rn
    FROM 
        title
    JOIN 
        aka_title mt ON title.imdb_index = mt.imdb_index
    JOIN 
        kind_type c1 ON mt.kind_id = c1.id
    WHERE 
        c1.kind IS NOT NULL
),

FinalResults AS (
    SELECT 
        mh.title AS movie_title,
        mh.production_year,
        tp.name AS top_performer,
        rt.title AS ranked_title,
        rt.rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        TopPerformers tp ON mh.movie_id IN (
            SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name LIKE '%Smith%')
        )
    LEFT JOIN 
        RankedTitles rt ON mh.movie_id = rt.id
    WHERE 
        mh.depth = 1 -- We're only interested in the top-level movies in the hierarchy
)

SELECT 
    COALESCE(F.movie_title, 'Unknown Movie') AS movie_title,
    COALESCE(F.production_year, 0) AS production_year,
    COALESCE(F.top_performer, 'No Actor') AS top_performer,
    COALESCE(F.ranked_title, 'Not Ranked') AS ranked_title,
    F.rn
FROM 
    FinalResults F
ORDER BY 
    F.production_year DESC, 
    F.movie_title ASC 
FETCH FIRST 50 ROWS ONLY; -- limiting the output for manageable results

