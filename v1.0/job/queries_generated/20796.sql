WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
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

ActorRanked AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS rank
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
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

MoviesWithKeywords AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        KeywordCounts kc ON mh.movie_id = kc.movie_id
),

TopMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.keyword_count,
        ar.movie_count
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        ActorRanked ar ON mwk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name LIKE '%Smith%'))
    WHERE 
        mwk.keyword_count > 5 AND
        mwk.production_year BETWEEN 2000 AND 2023
),

FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.keyword_count,
        tm.movie_count,
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    GROUP BY 
        tm.title, tm.production_year, tm.keyword_count, tm.movie_count
)

SELECT 
    fo.title,
    fo.production_year,
    fo.keyword_count,
    fo.movie_count,
    fo.company_count,
    CASE 
        WHEN fo.company_count IS NULL THEN 'No Companies Associated'
        WHEN fo.company_count = 0 THEN 'Independent Film'
        ELSE 'Multiple Productions'
    END AS company_association
FROM 
    FinalOutput fo
ORDER BY 
    fo.keyword_count DESC, 
    fo.movie_count DESC,
    fo.production_year DESC
LIMIT 100 OFFSET 0;
