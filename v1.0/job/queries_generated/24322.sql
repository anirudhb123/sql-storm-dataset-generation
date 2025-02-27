WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        ARRAY[m.title] AS path
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (
            SELECT id 
            FROM kind_type 
            WHERE kind = 'movie'
            LIMIT 1
        )
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        path || mt.title AS path
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.kind_id = (
            SELECT id 
            FROM kind_type 
            WHERE kind = 'movie'
            LIMIT 1
        )
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.level,
        rm.rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year IS NOT NULL AND
        rm.rank <= 5
)

SELECT 
    fm.title,
    fm.production_year,
    CASE 
        WHEN fm.production_year IS NULL THEN 'Unknown Year'
        ELSE TO_CHAR(fm.production_year)
    END AS production_year_string,
    COALESCE(cn.name, 'No Company') AS company_name,
    COALESCE(string_agg(DISTINCT ak.name, ', ' ORDER BY ak.name), 'No Cast') AS cast_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') FILTER (WHERE kw.keyword IS NOT NULL) AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, cn.name
ORDER BY 
    fm.production_year DESC, fm.title;

This SQL query showcases several advanced features:
- It uses a recursive Common Table Expression (CTE) to build a hierarchy of movies based on their links.
- It applies window functions to rank movies by production year.
- The query retrieves various details including the movie title, production year, company name, cast names, and associated keywords.
- It employs `COALESCE` to handle NULL values and `STRING_AGG` to concatenate results.
- It includes complex predicates and string formatting to enhance the output.
