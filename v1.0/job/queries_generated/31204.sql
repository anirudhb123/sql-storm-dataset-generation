WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- assuming kind_id=1 indicates feature films
    
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
MovieInfo AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ki.keyword) AS keywords,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        SUM(CASE WHEN co.company_type_id = 1 THEN 1 ELSE 0 END) AS production_company_count -- assuming company_type_id=1 is productions
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mi.keywords,
        mi.cast_count,
        mi.production_company_count,
        RANK() OVER (PARTITION BY mh.level ORDER BY mi.cast_count DESC, mi.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
    JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
),
FinalReport AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.cast_count,
        rm.production_company_count,
        rm.rank,
        CASE 
            WHEN rm.rank <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS category
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 0
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keywords,
    fr.cast_count,
    fr.production_company_count,
    fr.rank,
    fr.category
FROM 
    FinalReport fr
ORDER BY 
    fr.production_year DESC, fr.rank;
