
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        MovieHierarchy mh
    JOIN 
        complete_cast cc ON cc.movie_id = mh.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.kind_id
    HAVING 
        COUNT(ci.person_id) > 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
MovieWithInfo AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        mk.keywords,
        CASE 
            WHEN mt.kind_id IS NULL THEN 'Unknown' 
            ELSE (SELECT k.kind FROM kind_type k WHERE k.id = mt.kind_id)
        END AS movie_kind
    FROM 
        TopMovies mt
    LEFT JOIN 
        MovieKeywords mk ON mt.movie_id = mk.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.keywords,
    mw.movie_kind,
    COUNT(DISTINCT ci.person_id) AS unique_actors,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS avg_info_length,
    MAX(CASE WHEN pi.info IS NOT NULL THEN pi.info ELSE 'No Info' END) AS longest_info
FROM 
    MovieWithInfo mw
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mw.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id
WHERE 
    mw.production_year >= 2000
GROUP BY 
    mw.movie_id, mw.title, mw.production_year, mw.keywords, mw.movie_kind
ORDER BY 
    unique_actors DESC, mw.production_year DESC
LIMIT 10;
