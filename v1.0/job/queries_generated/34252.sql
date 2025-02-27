WITH RECURSIVE MovieHierachy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start with top-level movies

    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1
    FROM 
        aka_title AS et
    JOIN 
        MovieHierachy AS mh ON et.episode_of_id = mh.movie_id  -- Join on episodes
),

MovieScores AS (
    SELECT 
        m.id AS movie_id,
        COUNT(ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS clarity_score
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        (ms.actor_count * 0.6 + ms.clarity_score * 0.4) AS overall_score  -- Weighted score
    FROM 
        MovieHierachy AS mh
    JOIN 
        MovieScores AS ms ON mh.movie_id = ms.movie_id
    WHERE 
        mh.level = 1  -- Only take top-level movies
    ORDER BY 
        overall_score DESC
    LIMIT 10  -- Take top 10 movies
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ac.name, 'Unknown Actor') AS actor_name,
    COUNT(CASE WHEN kw.keyword IS NOT NULL THEN 1 END) AS keyword_count,
    COALESCE(cn.name, 'No Company') AS production_company
FROM 
    TopMovies AS tm
LEFT JOIN 
    cast_info AS ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS ac ON ci.person_id = ac.person_id
LEFT JOIN 
    movie_companies AS mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword AS mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
GROUP BY 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    ac.name,
    cn.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 2  -- Only movies with more than 2 actors
ORDER BY 
    tm.production_year DESC;
