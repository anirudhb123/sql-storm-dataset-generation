WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

CastRoles AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        ai.role_id,
        COUNT(*) OVER(PARTITION BY ai.role_id) AS role_count,
        ROW_NUMBER() OVER(PARTITION BY ai.person_id ORDER BY ai.nr_order) AS actor_order
    FROM 
        cast_info ai
    JOIN 
        aka_title at ON ai.movie_id = at.id
    WHERE 
        at.production_year >= 2000
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        CR.person_id,
        COUNT(DISTINCT CR.role_id) AS unique_roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastRoles CR ON mh.movie_id = CR.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
)

SELECT 
    md.movie_title,
    md.production_year,
    COALESCE(np.name, 'Unknown') AS director_name,
    md.unique_roles,
    CASE 
        WHEN md.production_year > 2010 THEN 'Recent'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Classic'
    END AS era,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
LEFT JOIN 
    aka_name np ON mi.info = np.id::text
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    md.movie_title, md.production_year, np.name
ORDER BY 
    md.production_year DESC, md.movie_title;

This query performs the following: 

1. **Recursive CTE (`MovieHierarchy`)** to fetch movies from the year 2000 onward and their linked movies, building a hierarchy.
2. **Window Functions** in `CastRoles` to calculate the count of roles per actor and rank them.
3. **Outer Joins** to gather detailed movie info including director.
4. **Aggregates** to group and count keywords associated with each movie.
5. An elaborate selection list including conditional logic for movie eras and handling NULL values with `COALESCE`.
6. **Final ordering** of the results. 

This formulation allows you to benchmark the performance of complex queries with various SQL constructs.
