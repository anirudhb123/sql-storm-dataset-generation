WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
),
CastInformation AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.actor_id) AS total_actors,
    MAX(ci.actor_order) AS longest_cast_order
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInformation ci ON mh.movie_id = ci.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.actor_id) > 5 OR MAX(ci.actor_order) IS NULL
ORDER BY 
    mh.production_year DESC, total_actors DESC
LIMIT 100;

-- Additional analysis for movies with strange titles (including NULLs and specific keywords)
WITH StrangeTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        kt.keyword
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        t.title LIKE '%s%' OR (kt.keyword IS NULL AND LENGTH(t.title) > 50)
),
TitleStats AS (
    SELECT 
        st.title,
        COUNT(*) AS occurrences
    FROM 
        StrangeTitles st
    GROUP BY 
        st.title
)
SELECT 
    ts.title,
    ts.occurrences
FROM 
    TitleStats ts
WHERE 
    ts.occurrences > 1
ORDER BY 
    ts.occurrences DESC
LIMIT 50;
