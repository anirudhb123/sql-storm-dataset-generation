WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Starting from top-level movies
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
ActorInfo AS (
    SELECT 
        ai.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ai.person_id, ak.name
),
MostFrequentKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
CombinedData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ai.actor_name,
        ak.movie_count,
        COALESCE(kws.keyword, 'No Keywords') AS keyword,
        kw.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY kw.keyword_count DESC) AS keyword_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorInfo ai ON ai.movie_id = mh.movie_id
    LEFT JOIN 
        MostFrequentKeywords kw ON mh.movie_id = kw.movie_id
    LEFT JOIN 
        keyword kws ON kw.keyword_id = kws.id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.actor_name,
    cd.movie_count,
    cd.keyword,
    cd.keyword_count
FROM 
    CombinedData cd
WHERE 
    cd.level = 1                          -- Only include top-level movies
    AND (cd.movie_count > 1 OR cd.keyword_count IS NULL)  -- At least 2 movies or no keywords
ORDER BY 
    cd.production_year DESC,
    cd.movie_count DESC;
