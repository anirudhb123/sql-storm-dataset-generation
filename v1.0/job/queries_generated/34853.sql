WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL 

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.level + 1 AS level,
        mh.path || mt.id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        a.name AS actor_name,
        a.id AS actor_id,
        COALESCE(mk.keyword, 'None') AS keyword,
        COALESCE(mci.kind, 'Unknown') AS company_type,
        COUNT(ci.id) FILTER (WHERE ci.person_role_id IS NOT NULL) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type mci ON mc.company_type_id = mci.id
    GROUP BY 
        m.id, m.title, a.name, mk.keyword, mci.kind
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.actor_name,
        md.actor_id,
        md.keyword,
        md.company_type,
        md.role_count,
        ROW_NUMBER() OVER (ORDER BY md.role_count DESC, md.title ASC) AS rank
    FROM 
        MovieDetails md
    WHERE 
        md.role_count > 0 
        AND md.keyword <> 'None'
)
SELECT 
    mh.movie_id AS episode_id,
    mh.title AS episode_title,
    r.actor_name,
    r.keyword,
    r.company_type,
    r.role_count,
    r.rank,
    CASE 
        WHEN r.rank <= 10 THEN 'Top 10 Episodes'
        ELSE 'Other Episodes'
    END AS episode_category,
    COALESCE(NULLIF(r.keyword, ''), 'No Keywords') AS safe_keyword
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies r ON mh.movie_id = r.movie_id
WHERE 
    mh.level = 1
ORDER BY 
    mh.title ASC,
    r.rank NULLS LAST;
