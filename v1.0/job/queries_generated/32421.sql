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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
CastRanking AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TitleWithKeywords AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id, at.title
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.cast_count, 0) AS total_cast,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    mc.company_type AS company_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRanking cr ON mh.movie_id = cr.movie_id AND cr.rank = 1
LEFT JOIN 
    TitleWithKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON mh.movie_id = mc.movie_id AND mc.rn = 1
WHERE 
    mh.level <= 2
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC;
