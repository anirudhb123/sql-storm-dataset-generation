WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS hierarchy_level,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.hierarchy_level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mk ON mh.movie_id = mk.movie_id
    JOIN 
        aka_title m ON mk.linked_movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.hierarchy_level,
        ROW_NUMBER() OVER (PARTITION BY mh.hierarchy_level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),

FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.hierarchy_level,
        CASE 
            WHEN rm.hierarchy_level < 3 THEN 'Low Depth'
            WHEN rm.hierarchy_level BETWEEN 3 AND 5 THEN 'Medium Depth'
            ELSE 'High Depth'
        END AS depth_category
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)

SELECT 
    fm.*,
    ak.name AS first_person_name,
    ct.kind AS company_type,
    ci.note AS cast_info_note
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    fm.production_year > 2000
ORDER BY 
    fm.hierarchy_level, fm.production_year DESC;
