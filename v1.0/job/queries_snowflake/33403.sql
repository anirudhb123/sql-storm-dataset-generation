
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.season_nr IS NULL  
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id  
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
TitleStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(h.level, 0) AS hierarchy_level,
        cd.total_cast,
        cd.cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        MovieHierarchy h ON t.id = h.movie_id  
    LEFT JOIN 
        CastDetails cd ON t.id = cd.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ts.title,
    ts.production_year,
    ts.hierarchy_level,
    COALESCE(ts.total_cast, 0) AS total_cast,
    COALESCE(ts.cast_names, 'No cast available') AS cast_names,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    TitleStats ts
LEFT JOIN 
    MovieKeywords mk ON ts.movie_id = mk.movie_id
WHERE 
    ts.production_year >= 2000  
ORDER BY 
    ts.production_year DESC,
    ts.hierarchy_level,
    ts.total_cast DESC;
