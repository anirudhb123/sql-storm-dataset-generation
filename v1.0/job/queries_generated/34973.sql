WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rank
    FROM 
        MovieHierarchy mh
),
AggregateData AS (
    SELECT 
        ct.kind AS company_kind,
        COUNT(DISTINCT mc.movie_id) AS movies_count,
        AVG(ki.production_year) AS avg_production_year
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title ki ON mc.movie_id = ki.movie_id
    GROUP BY 
        ct.kind
)
SELECT 
    jm.rank,
    jm.title,
    jm.production_year,
    ad.company_kind,
    ad.movies_count,
    ad.avg_production_year,
    (CASE 
        WHEN ad.avg_production_year IS NULL 
        THEN 'No Data' 
        ELSE TO_CHAR(ad.avg_production_year, '9999')
    END) AS avg_prod_year_formatted
FROM 
    RankedMovies jm
LEFT JOIN 
    AggregateData ad ON jm.production_year = ad.avg_production_year
WHERE 
    jm.rank <= 5
ORDER BY 
    jm.production_year DESC, 
    jm.rank;
