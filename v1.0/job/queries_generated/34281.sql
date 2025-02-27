WITH RECURSIVE CastHierarchy AS (
    SELECT 
        ci.movie_id,
        ca.person_id,
        ca.role_id,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    WHERE 
        ci.nr_order = 1
    
    UNION ALL
    
    SELECT 
        ci.movie_id,
        ca.person_id,
        ci.role_id,
        ch.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    JOIN 
        CastHierarchy ch ON ci.movie_id = ch.movie_id
    WHERE 
        ci.nr_order > ch.level
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
),
RelatedMovies AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        lt.link AS relationship_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    r.actor_count,
    rh.relationship_type,
    COALESCE(a.name, 'Unknown') AS actor_name,
    (SELECT COUNT(DISTINCT ci2.person_id) 
     FROM cast_info ci2
     WHERE ci2.movie_id = t.id AND ci2.person_id IS NOT NULL) AS total_actors_in_movie,
    ch.level AS cast_hierarchy_level
FROM 
    title t
LEFT JOIN 
    RankedMovies r ON t.title = r.title
LEFT JOIN 
    RelatedMovies rh ON t.id = rh.movie_id
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    CastHierarchy ch ON t.id = ch.movie_id 
WHERE 
    t.production_year >= 2000 AND
    (r.actor_count > 5 OR rh.relationship_type IS NOT NULL)
ORDER BY 
    r.actor_count DESC, 
    t.production_year DESC;
