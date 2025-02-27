WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS null_note_ratio
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        cs.distinct_cast_count,
        cs.null_note_ratio,
        ROW_NUMBER() OVER (PARTITION BY cs.distinct_cast_count ORDER BY cs.null_note_ratio DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStatistics cs ON mh.movie_id = cs.movie_id
)
SELECT 
    rm.title,
    rm.distinct_cast_count,
    rm.null_note_ratio,
    CASE 
        WHEN rm.null_note_ratio IS NULL THEN 'No data'
        WHEN rm.null_note_ratio > 0.5 THEN 'High NULL ratio'
        ELSE 'Low NULL ratio'
    END AS note_analysis,
    COUNT(DISTINCT mci.id) FILTER (WHERE ct.kind IS NOT NULL) AS distinct_company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_companies mci ON rm.movie_id = mci.movie_id
LEFT JOIN 
    company_name cn ON mci.company_id = cn.id
LEFT JOIN 
    company_type ct ON mci.company_type_id = ct.id
WHERE 
    rm.rank <= 10
GROUP BY 
    rm.movie_id, rm.title, rm.distinct_cast_count, rm.null_note_ratio
ORDER BY 
    rm.distinct_cast_count DESC, rm.null_note_ratio ASC;
