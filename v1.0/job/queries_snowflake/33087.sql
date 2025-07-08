
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season,
        COALESCE(mt.episode_nr, 0) AS episode,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season,
        COALESCE(mt.episode_nr, 0) AS episode,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

CompleteCast AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT CONCAT(an.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY an.name) AS actors
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    mh.season,
    mh.episode,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    COALESCE(cc.actors, 'No Cast') AS complete_cast
FROM 
    MovieHierarchy mh
LEFT JOIN 
    KeywordCounts kc ON mh.movie_id = kc.movie_id
LEFT JOIN 
    CompleteCast cc ON mh.movie_id = cc.movie_id
WHERE 
    mh.level = 1 
    AND mh.production_year > 2000
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;
