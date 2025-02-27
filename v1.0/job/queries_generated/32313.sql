WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.title) AS title_rank
    FROM 
        MovieHierarchy mh
),
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(DISTINCT mc.id) AS total_companies,
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS companies_with_notes
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.depth,
    cms.company_name,
    cms.total_companies,
    cms.companies_with_notes,
    (SELECT COUNT(*) 
        FROM movie_info mi 
        WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = 1) AS info_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
        FROM movie_keyword mk 
        JOIN keyword k ON mk.keyword_id = k.id 
        WHERE mk.movie_id = rm.movie_id) AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieStats cms ON rm.movie_id = cms.movie_id
WHERE 
    rm.depth <= 2
ORDER BY 
    rm.depth, rm.title_rank;
