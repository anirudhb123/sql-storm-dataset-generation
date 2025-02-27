WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        title m 
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COALESCE(cnk.kind, 'Unclassified') AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type cnk ON mc.company_type_id = cnk.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rn <= 5
GROUP BY 
    tm.title, tm.production_year, tm.total_cast, a.name, cnk.kind
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
