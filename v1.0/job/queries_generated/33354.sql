WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind='movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN mp.company_type_id = (SELECT id FROM company_type WHERE kind='Production') 
                 THEN cn.name ELSE NULL END) AS production_company
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mp ON mh.movie_id = mp.movie_id
    LEFT JOIN 
        company_name cn ON mp.company_id = cn.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
RankedMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.keyword_count,
        ms.production_company,
        RANK() OVER (ORDER BY ms.cast_count DESC, ms.keyword_count DESC) AS rank
    FROM 
        MovieStats ms
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    COALESCE(rm.cast_count, 0) AS total_cast,
    COALESCE(rm.keyword_count, 0) AS total_keywords,
    COALESCE(rm.production_company, 'Independent') AS production_company
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
