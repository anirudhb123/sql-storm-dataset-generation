WITH RECURSIVE MovieHierachy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierachy mh ON mh.movie_id = ml.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Info') AS info,
        COALESCE(g.kind, 'Unknown') AS genre
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id
    LEFT JOIN 
        kind_type g ON g.id = m.kind_id
),
CastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MIN(r.role) AS primary_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        c.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mi.info,
        ci.total_cast,
        ci.primary_role,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC, ci.total_cast DESC) AS rank
    FROM 
        MovieHierachy mh
    JOIN 
        MovieInfo mi ON mi.movie_id = mh.movie_id
    LEFT JOIN 
        CastInfo ci ON ci.movie_id = mh.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.info,
    rm.total_cast,
    rm.primary_role,
    COALESCE(mk.keyword, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.primary_role IS NULL THEN 'No Cast'
        ELSE rm.primary_role
    END AS final_role
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = rm.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
