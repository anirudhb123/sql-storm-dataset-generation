WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        mc.company_id IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
    WHERE 
        mc.company_id IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
KeywordAgg AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(ka.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.production_year < 1990 THEN 'Classic'
        WHEN mh.production_year BETWEEN 1990 AND 2010 THEN 'Modern'
        WHEN mh.production_year > 2010 THEN 'Recent'
        ELSE 'Unknown'
    END AS era_category,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY ac.actor_count DESC) AS actor_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorCount ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    KeywordAgg ka ON mh.movie_id = ka.movie_id
WHERE 
    (mh.level = 1 OR mh.parent_id IS NULL)
    AND (mh.production_year IS NOT NULL OR mh.production_year >= 2000)
ORDER BY 
    mh.production_year DESC,
    actor_rank
LIMIT 100;
