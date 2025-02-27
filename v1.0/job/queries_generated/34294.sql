WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' > ', mt.title)
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        mh.path,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        KeywordCounts kc ON mh.movie_id = kc.movie_id
    WHERE 
        mh.level = 0 AND 
        mh.production_year >= 2000 
    ORDER BY 
        mh.production_year DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.path,
    COALESCE(ck.name, 'Unknown') AS character_name,
    cc.kind AS company_kind,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT ca.person_id) AS cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    char_name ck ON ca.person_role_id = ck.imdb_id
LEFT JOIN 
    movie_keyword kw ON tm.movie_id = kw.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.keyword_count > 5 
GROUP BY 
    tm.title, tm.production_year, tm.path, ck.name, cc.kind
ORDER BY 
    COUNT(DISTINCT ca.person_id) DESC, tm.production_year DESC;
