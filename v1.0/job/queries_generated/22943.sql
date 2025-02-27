WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.kind AS movie_type,
        cc.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY cmp.id) AS rn
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_companies AS cmp ON m.id = cmp.movie_id
    LEFT JOIN 
        company_type AS cc ON cmp.company_type_id = cc.id
    WHERE 
        m.production_year >= 2000
    UNION ALL 
    SELECT
        m.id,
        m.title,
        m.production_year,
        mt.kind,
        cc.kind,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY cmp.id) AS rn
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        movie_companies AS cmp ON m.id = cmp.movie_id
    LEFT JOIN 
        company_type AS cc ON cmp.company_type_id = cc.id
    WHERE 
        m.production_year >= 2000 AND 
        mh.movie_id <> m.id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.movie_type,
        mh.company_type,
        COUNT(*) OVER (PARTITION BY mh.movie_id) AS company_count,
        COALESCE(NULLIF(mh.movie_type, 'Documentary'), 'Unknown') AS adjusted_movie_type
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.rn = 1
)
SELECT 
    fm.title,
    fm.production_year,
    fm.adjusted_movie_type,
    CASE 
        WHEN fm.company_count > 1 THEN 'Multiple Companies' 
        ELSE COALESCE(fm.company_type, 'No Companies') 
    END AS company_status,
    STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
    COUNT(DISTINCT k.keyword) AS distinct_keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    complete_cast AS cc ON fm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name AS c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword AS mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    (fm.production_year IS NOT NULL AND fm.production_year BETWEEN 2000 AND 2023)
    AND (fm.company_type IS NOT NULL OR fm.company_count > 0)
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.adjusted_movie_type, fm.company_count
ORDER BY 
    fm.production_year DESC, fm.title ASC
LIMIT 100;
