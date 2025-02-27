WITH RECURSIVE movie_hierarchy AS (
    -- Start with the top-level movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- This should filter for actual 'movies'

    UNION ALL

    -- Recursive part to get linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    mk.keyword AS movie_keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    ARRAY_AGG(DISTINCT mt.title) AS movies,
    AVG(EXTRACT(YEAR FROM now()) - mh.production_year) AS average_movie_age
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    a.name, mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    average_movie_age DESC;

-- Additional analysis on companies involved in these movies
WITH company_analysis AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1
)

SELECT 
    mh.title AS movie_title,
    ca.company_name,
    ca.company_type,
    ca.num_companies
FROM 
    movie_hierarchy mh
JOIN 
    company_analysis ca ON mh.movie_id = ca.movie_id
ORDER BY 
    mh.production_year DESC, ca.num_companies DESC;

This complex query utilizes common table expressions (CTEs) for recursive retrieval of movies linked through relationships, aggregates actor information alongside the number of unique movies, and further analyzes the involvement of companies in these films, providing a detailed performance benchmarking perspective.
