WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        0 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.name LIKE '%Studio%'  -- Selecting movies made by Studios
    
    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        complete_cast m
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)

SELECT 
    title,
    AVG(depth) AS avg_depth,
    COUNT(DISTINCT person_id) AS actor_count, 
    COUNT(DISTINCT movie_id) AS unique_movies,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    SUM(COALESCE(mk.count, 0)) AS total_keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id 
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    company_name cn ON ci.movie_id = cn.id  -- Interesting to join with company_name here
GROUP BY 
    mh.title
HAVING 
    AVG(depth) > 1 AND
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    avg_depth DESC, unique_movies DESC
LIMIT 10;

WITH KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(*) AS count 
    FROM 
        movie_keyword mk
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%%action%%')
    GROUP BY 
        mk.movie_id
),

HighRatingMovies AS (
    SELECT 
        m.id AS movie_id,
        AVG(mr.rating) AS avg_rating
    FROM 
        aka_title m
    JOIN 
        movie_info mi ON mi.movie_id = m.id
    JOIN 
        info_type it ON it.id = mi.info_type_id
    WHERE 
        it.info = 'rating' AND
        mi.info IS NOT NULL
    GROUP BY 
        m.id
)

SELECT 
    mh.title,
    hk.count AS keyword_count,
    hr.avg_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    KeywordCounts hk ON mh.movie_id = hk.movie_id
LEFT JOIN 
    HighRatingMovies hr ON mh.movie_id = hr.movie_id
WHERE 
    (hr.avg_rating IS NULL OR hr.avg_rating > 7.5)  -- Mystery around NULL values
ORDER BY 
    keyword_count DESC NULLS LAST
LIMIT 10;

-- Finalizing the results
SELECT 
    * 
FROM 
    (SELECT 
        mh.title,
        AVG(depth) AS avg_depth,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mh.movie_id) AS unique_movies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id 
    LEFT JOIN 
        company_name cn ON ci.movie_id = cn.id -- Outer join
    GROUP BY 
        mh.title
    HAVING 
        AVG(depth) > 1
        AND NOT EXISTS (SELECT 1 FROM role_type rt WHERE rt.id = ci.role_id AND rt.role LIKE '%%extra%%') -- Bizarre logic
    ) AS FinalResults
ORDER BY 
    unique_movies DESC
LIMIT 5;
