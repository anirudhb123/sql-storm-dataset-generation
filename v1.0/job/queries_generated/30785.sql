WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        h.level < 5
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COUNT(DISTINCT ca.person_id) AS Total_Cast,
    AVG(CASE 
            WHEN ca.nr_order IS NULL THEN 0 
            ELSE ca.nr_order 
        END) AS Average_Order,
    STRING_AGG(DISTINCT ak.name, ', ') AS Actor_Names
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN 
    aka_name ak ON ca.person_id = ak.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
ORDER BY 
    AVG(ca.nr_order) DESC NULLS LAST
LIMIT 10;

-- Additional performance benchmarking based on movie keywords
WITH KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),

MostPopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        kc.keyword_count,
        ROW_NUMBER() OVER (ORDER BY kc.keyword_count DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        KeywordCounts kc ON m.id = kc.movie_id
    WHERE 
        m.production_year >= 2010
)

SELECT 
    mp.movie_id,
    mp.title,
    mp.keyword_count,
    COALESCE(r.role, 'Unknown Role') AS role
FROM 
    MostPopularMovies mp
LEFT JOIN 
    cast_info ci ON mp.movie_id = ci.movie_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    mp.rank <= 20
ORDER BY 
    mp.keyword_count DESC, mp.title;
