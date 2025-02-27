WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2022
    UNION ALL
    SELECT 
        m.id,
        m.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
),

TopActors AS (
    SELECT 
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        MAX(ct.kind) AS role_kind
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
    ORDER BY 
        movie_count DESC
    LIMIT 10
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        STRING_AGG(DISTINCT ak.name, ', ') AS top_cast,
        COALESCE(mi.info, 'N/A') AS additional_info,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mh.movie_id, mh.title, mi.info
)

SELECT 
    md.title,
    md.top_cast,
    md.additional_info,
    md.keyword_count,
    ta.name AS top_actor,
    ta.movie_count,
    ta.role_kind
FROM 
    MovieDetails md
LEFT JOIN 
    TopActors ta ON md.top_cast LIKE '%' || ta.name || '%'
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.keyword_count DESC,
    md.title ASC
LIMIT 50;
