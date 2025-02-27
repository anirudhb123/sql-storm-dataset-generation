
WITH RECURSIVE MovieHierarchies AS (
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')  
    
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchies mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),
TopRatedMovies AS (
    
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (ORDER BY AVG(CAST(mvi.info AS numeric)) DESC) AS ranking
    FROM 
        title t
    JOIN 
        movie_info mvi ON t.id = mvi.movie_id
    WHERE 
        mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        t.id, t.title
    HAVING 
        AVG(CAST(mvi.info AS numeric)) >= 7.0
),
CastCount AS (
    
    SELECT 
        mh.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        MovieHierarchies mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id AND c.movie_id = mh.movie_id
    GROUP BY 
        mh.movie_id
)
SELECT 
    tr.title,
    tr.ranking,
    COALESCE(cc.actor_count, 0) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    TopRatedMovies tr
LEFT JOIN 
    CastCount cc ON tr.movie_id = cc.movie_id
LEFT JOIN 
    complete_cast cc2 ON tr.movie_id = cc2.movie_id
LEFT JOIN 
    cast_info c ON cc2.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    cc.actor_count IS NOT NULL
    AND c.note IS NOT NULL
GROUP BY 
    tr.movie_id, tr.title, tr.ranking, cc.actor_count
ORDER BY 
    tr.ranking
LIMIT 10;
