WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
),

MovieRanked AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.keyword,
        ROW_NUMBER() OVER (PARTITION BY mh.keyword ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
)

SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    CASE 
        WHEN m.rank = 1 THEN 'Top Movie of Keyword'
        WHEN m.rank <= 5 THEN 'Top 5 Movies of Keyword'
        ELSE 'Other Movies'
    END AS movie_ranking,
    COALESCE(n.name, 'Unknown') AS director_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    MovieRanked m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id AND ci.person_role_id = (
        SELECT id FROM role_type WHERE role = 'Director'
    )
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
LEFT JOIN 
    movie_keyword k ON m.movie_id = k.movie_id
GROUP BY 
    m.movie_id, m.movie_title, m.production_year, m.rank, n.name
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    m.production_year DESC, m.keyword;

