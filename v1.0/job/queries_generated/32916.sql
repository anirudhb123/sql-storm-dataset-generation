WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        md5sum,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        mm.md5sum,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
),

PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS employee_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(pm.cast_count, 0) AS total_cast,
    cd.company_name,
    cd.company_type,
    cd.employee_count,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS named_roles,
    (SELECT AVG(production_year) 
     FROM aka_title 
     WHERE production_year IS NOT NULL) AS avg_production_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    PopularMovies pm ON mh.movie_id = pm.movie_id
LEFT JOIN 
    CompanyDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
WHERE 
    mh.level = 0
ORDER BY 
    mh.production_year DESC, mh.title;
