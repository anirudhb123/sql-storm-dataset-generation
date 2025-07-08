WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year = 2023

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        m.title IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.person_id,
        a.name,
        c.movie_id,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
RelevantMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(cd.person_id) AS total_cast
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title
    HAVING 
        COUNT(cd.person_id) >= 5
),
DetailedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        mv.info AS movie_info,
        COALESCE(com.name, 'No Company') AS company_name,
        rp.role AS primary_role
    FROM 
        RelevantMovies rm
    LEFT JOIN 
        movie_info mv ON rm.movie_id = mv.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name com ON mc.company_id = com.id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        role_type rp ON ci.role_id = rp.id
),
FinalOutput AS (
    SELECT 
        dmi.movie_id,
        dmi.title,
        dmi.movie_info,
        dmi.company_name,
        dmi.primary_role,
        ROW_NUMBER() OVER (ORDER BY dmi.title) AS row_num
    FROM 
        DetailedMovieInfo dmi
    WHERE 
        dmi.movie_info IS NOT NULL
)
SELECT 
    fo.*,
    CASE 
        WHEN fo.company_name IS NULL THEN 'Unknown Company' 
        ELSE fo.company_name 
    END AS resolved_company_name
FROM 
    FinalOutput fo
WHERE 
    fo.row_num <= 10
ORDER BY 
    fo.title;
