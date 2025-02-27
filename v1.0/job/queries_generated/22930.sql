WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1,
        mh.movie_id
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind
    FROM 
        title t
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000 AND 
        t.title NOT ILIKE '%remake%' AND 
        t.title NOT ILIKE '%copy%'
),
KeywordStats AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    WHERE 
        mk.movie_id IN (SELECT id FROM TitleInfo)
    GROUP BY 
        mk.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT pr.role ORDER BY pr.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type pr ON ci.role_id = pr.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.level,
    ti.kind,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(ar.actor_count, 0) AS actor_count,
    ar.roles,
    CASE 
        WHEN mh.level > 2 THEN 'Sequel or Spin-off'
        ELSE 'Original'
    END AS classification,
    STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TitleInfo ti ON mh.movie_id = ti.title_id
LEFT JOIN 
    KeywordStats ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL AND cn.name NOT ILIKE '%films%'
GROUP BY 
    mh.movie_id, mh.movie_title, mh.level, ti.kind, ks.keyword_count, ar.actor_count, ar.roles
HAVING 
    (mh.level <= 2 OR COUNT(DISTINCT cn.name) > 2)
ORDER BY 
    mh.level ASC, ar.actor_count DESC NULLS LAST, ti.production_year DESC;
