WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', t.title) AS path
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        mh.level < 5
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_level
    FROM 
        MovieHierarchy mh
),
FinalMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.level,
        rm.rank_level,
        COALESCE(kw.keyword, 'No Keyword') AS keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.level,
    f.rank_level,
    STRING_AGG(f.keyword, ', ') AS keywords
FROM 
    FinalMovies f
WHERE 
    f.rank_level <= 3
GROUP BY 
    f.movie_id, f.title, f.production_year, f.level, f.rank_level
ORDER BY 
    f.production_year DESC, f.level ASC;
