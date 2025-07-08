
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        m.title AS path
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.path || ' > ' || m.title AS path
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
), 

TitleWithKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),

CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS cast_count,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COALESCE(tkw.keywords, 'No keywords') AS keywords,
    COALESCE(cir.cast_count, 0) AS cast_count,
    COALESCE(cir.roles, 'No roles assigned') AS roles
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TitleWithKeywords tkw ON mh.movie_id = tkw.title_id
LEFT JOIN 
    CastInfoWithRoles cir ON mh.movie_id = cir.movie_id
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;
