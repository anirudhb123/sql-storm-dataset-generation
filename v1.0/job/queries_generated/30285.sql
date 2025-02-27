WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title at ON mc.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT cs.role_id) AS total_roles,
        COUNT(DISTINCT p.id) AS total_cast
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info cs ON mc.movie_id = cs.movie_id
    LEFT JOIN 
        aka_name p ON cs.person_id = p.person_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

FinalReport AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.company_name,
        cs.company_type,
        cs.total_roles,
        cs.total_cast,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.total_cast DESC) AS cast_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CompanyStats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)

SELECT 
    *
FROM 
    FinalReport
WHERE 
    total_cast IS NOT NULL
    AND (production_year > 2010 OR company_type LIKE '%Production%')
ORDER BY 
    production_year DESC, total_roles DESC;
