WITH RecursiveMovieCTE AS (
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
        rm.level + 1
    FROM 
        RecursiveMovieCTE rm
    JOIN 
        movie_link ml ON rm.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        rm.level < 3 -- Limiting the depth of recursion
),

TopKeywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cast_aggregate.cast_list, '{}') AS cast_list
    FROM 
        RecursiveMovieCTE rm
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            STRING_AGG(a.name, ', ') AS cast_list
        FROM 
            cast_info ci
        JOIN 
            aka_name a ON ci.person_id = a.person_id
        GROUP BY 
            ci.movie_id
    ) cast_aggregate ON rm.movie_id = cast_aggregate.movie_id
)

SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    tk.keywords_list,
    ROW_NUMBER() OVER (PARTITION BY mwc.production_year ORDER BY mwc.title) AS title_rank,
    CASE 
        WHEN mwc.title ILIKE '%sequel%' THEN 'Sequel'
        WHEN mwc.production_year IS NULL THEN 'Year Unknown'
        ELSE 'Standard'
    END AS movie_type
FROM 
    MoviesWithCast mwc
LEFT JOIN 
    TopKeywords tk ON mwc.movie_id = tk.movie_id
WHERE 
    mwc.production_year >= 2000
    AND (mwc.title IS NOT NULL AND mwc.title <> '')
    AND mwc.movie_id IN (SELECT DISTINCT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'box office'))
ORDER BY 
    mwc.production_year DESC,
    title_rank
FETCH FIRST 100 ROWS ONLY;
