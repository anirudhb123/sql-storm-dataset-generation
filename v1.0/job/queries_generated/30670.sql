WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        et.production_year,
        mh.level + 1
    FROM 
        aka_title et
    INNER JOIN 
        movie_link ml ON et.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        COALESCE(CAST(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE NULL END) AS INTEGER), 0) AS total_cast
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year, mh.level
),
MoviesWithKeywords AS (
    SELECT 
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        fm.level,
        fm.total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.movie_id, fm.movie_title, fm.production_year, fm.level, fm.total_cast
)

SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.level,
    mwk.total_cast,
    mwk.keywords,
    RANK() OVER (PARTITION BY mwk.level ORDER BY mwk.total_cast DESC) AS cast_rank,
    CASE 
        WHEN mwk.keywords IS NULL THEN 'No Keywords'
        ELSE mwk.keywords
    END AS formatted_keywords,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = mwk.movie_id
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    ) AS box_office_info_count
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.production_year >= 2000
ORDER BY 
    mwk.level, cast_rank;
