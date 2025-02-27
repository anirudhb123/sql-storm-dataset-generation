
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.name AS company_name,
        1 AS depth
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name mt ON mc.company_id = mt.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.name AS company_name,
        mh.depth + 1 AS depth
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.id = mh.movie_id
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        aka_title lm ON ml.movie_id = lm.id
    LEFT JOIN 
        movie_companies mc ON lm.id = mc.movie_id
    LEFT JOIN 
        company_name mt ON mc.company_id = mt.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.company_name,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rank_depth
    FROM 
        MovieHierarchy mh
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_name
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_depth <= 5
)

SELECT 
    title.title, 
    ARRAY_AGG(DISTINCT fm.company_name) AS companies,
    COUNT(DISTINCT cc.subject_id) AS total_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    FilteredMovies fm
JOIN 
    complete_cast cc ON fm.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    title ON fm.movie_id = title.id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    title.title
ORDER BY 
    total_actors DESC
LIMIT 10;
