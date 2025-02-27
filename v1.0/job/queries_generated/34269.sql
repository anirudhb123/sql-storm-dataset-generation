WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        mt.kind_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1,
        at.production_year,
        at.kind_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
),
ParsedCompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    pm.info AS person_info,
    pc.company_names,
    pc.company_types,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    MAX(CASE WHEN ci.role_id IS NULL THEN 'Unknown' ELSE rt.role END) AS lead_role,
    COUNT(DISTINCT km.keyword) AS num_keywords,
    CASE 
        WHEN rm.production_year IS NULL THEN 'No Year' 
        ELSE TO_CHAR(rm.production_year) 
    END AS production_year_str
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info pm ON ci.person_id = pm.person_id
LEFT JOIN 
    ParsedCompanyData pc ON rm.movie_id = pc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    pm.info_type_id IS NULL OR pm.info_type_id != 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, pm.info, pc.company_names, pc.company_types
HAVING 
    COUNT(DISTINCT ci.person_id) > 10
ORDER BY 
    rm.production_year DESC, rm.movie_rank;
