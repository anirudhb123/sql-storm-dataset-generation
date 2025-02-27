WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastSummary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
CompanySummary AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.cast_count,
        cs.cast_names,
        coalesce(cp.companies, 'No Companies') AS companies,
        coalesce(cp.company_types, 'No Types') AS company_types,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastSummary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        CompanySummary cp ON mh.movie_id = cp.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    md.companies,
    md.company_types,
    CASE 
        WHEN md.cast_count IS NULL THEN 'No Cast Information'
        WHEN md.cast_count = 0 THEN 'No Cast'
        ELSE CAST(md.cast_count AS TEXT) || ' Cast Members'
    END AS cast_info,
    ARRAY_AGG(DISTINCT kw.keyword) FILTER (WHERE kw.keyword IS NOT NULL) AS keywords
FROM 
    MovieData md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    md.production_year BETWEEN 1990 AND 2023
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count, md.cast_names, md.companies, md.company_types
ORDER BY 
    md.production_year DESC, md.title;
