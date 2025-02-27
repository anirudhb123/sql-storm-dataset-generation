
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255)) AS path
    FROM 
        movie_link m
    JOIN 
        aka_title at ON m.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.level < 4
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        mh.path,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        MovieHierarchy mh
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.level,
        rm.path
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 3
)

SELECT 
    fm.title,
    fm.production_year,
    COUNT(cc.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(GROUP_CONCAT(k.keyword), 'No Keywords') AS keywords,
    CASE 
        WHEN fm.production_year > 2015 
        THEN 'Recent Release' 
        ELSE 'Older Film' 
    END AS release_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info cc ON fm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.level, fm.path
ORDER BY 
    fm.production_year DESC, cast_count DESC;
