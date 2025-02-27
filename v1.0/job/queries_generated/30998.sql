WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedRoles AS (
    SELECT
        ci.role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
),
TopRoles AS (
    SELECT
        ar.role_id,
        ar.role_count,
        ROW_NUMBER() OVER (ORDER BY ar.role_count DESC) AS rank
    FROM 
        AggregatedRoles ar
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(SUM(CASE WHEN mci.status_id = 1 THEN 1 ELSE 0 END), 0) AS completed_cast_count,
        COUNT(DISTINCT ki.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast mci ON mh.movie_id = mci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.completed_cast_count,
        md.keyword_count,
        TRIM(CONCAT(md.title, ' (', md.production_year, ')')) AS title_year,
        CASE 
            WHEN md.completed_cast_count > 0 THEN 'Completed' 
            ELSE 'Not Completed' 
        END AS cast_status
    FROM 
        MovieDetails md
    WHERE 
        md.production_year BETWEEN 2000 AND 2023
)
SELECT 
    fr.title_year,
    fr.cast_status,
    tr.role_count
FROM 
    FinalResults fr
LEFT JOIN 
    TopRoles tr ON fr.completed_cast_count > 0 AND fr.completed_cast_count <= 5
WHERE 
    fr.keyword_count > 0
ORDER BY 
    fr.production_year DESC, fr.title_year;
