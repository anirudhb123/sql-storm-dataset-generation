WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        ak.title,
        mh.level + 1,
        ak.production_year
    FROM 
        movie_link ml
    JOIN aka_title ak ON ml.linked_movie_id = ak.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.level ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mw.keyword_id) AS total_keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mw ON tm.movie_id = mw.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    WHERE 
        tm.movie_rank <= 10
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    fm.title,
    fm.total_cast,
    fm.total_keywords,
    COALESCE(MIN(mi.info), 'No Info') AS min_info,
    COALESCE(MAX(mi.info), 'No Info') AS max_info,
    AVG(CASE 
            WHEN ci.note IS NULL THEN 0 
            ELSE 1 
        END) AS avg_note_present
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
GROUP BY 
    fm.movie_id, fm.title
ORDER BY 
    fm.total_cast DESC, fm.total_keywords DESC;
