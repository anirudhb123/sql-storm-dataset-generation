WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM aka_title mt
    WHERE mt.production_year = (
        SELECT MAX(production_year) FROM aka_title
    )
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM aka_title m
    JOIN MovieHierarchy mh ON mh.movie_id = m.episode_of_id
),

ActorRoleCounts AS (
    SELECT 
        ci.person_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.person_id, a.name
),

MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY m.id, m.title, m.production_year
),

HighProfileMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        ac.actor_name,
        ac.movie_count,
        mh.level
    FROM MovieDetails md
    JOIN MovieHierarchy mh ON md.movie_id = mh.movie_id
    JOIN ActorRoleCounts ac ON ac.movie_count > 5
)

SELECT 
    hpm.title,
    hpm.production_year,
    hpm.actor_name,
    hpm.movie_count,
    mh.level
FROM HighProfileMovies hpm
JOIN MovieHierarchy mh ON hpm.movie_id = mh.movie_id
WHERE 
    hpm.production_year > 2000
    OR (mh.level IS NOT NULL AND mh.level = 2)
ORDER BY 
    hpm.movie_count DESC NULLS LAST, 
    hpm.production_year DESC;

