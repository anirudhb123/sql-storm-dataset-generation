WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(mi.profit_loss) AS average_profit_loss,
    m.production_year - COALESCE(MIN(mi.info_type_id), 0) AS production_adjustment
FROM 
    aka_title m
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    m.production_year IS NOT NULL
    AND m.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    average_profit_loss DESC
LIMIT 10;

-- Performance Benchmarking Query
EXPLAIN ANALYZE
WITH OrderedTitles AS (
    SELECT 
        t.id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year > 2010
),
ActorRoles AS (
    SELECT 
        c.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.person_id, rt.role
    HAVING 
        COUNT(*) > 2
)
SELECT 
    ot.id AS title_id,
    ot.title_rank,
    ar.person_id,
    ar.role,
    ar.role_count
FROM 
    OrderedTitles ot
LEFT JOIN 
    ActorRoles ar ON ar.person_id IN (
        SELECT 
            person_id 
        FROM 
            aka_name 
        WHERE 
            name ILIKE '%John%'
    )
WHERE 
    ot.title_rank < 20
ORDER BY 
    ot.title_rank;
