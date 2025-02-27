WITH RankedActors AS (
    SELECT 
        ka.person_id,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.person_id, ka.name
),
PopularMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5 -- movies with more than 5 actors
),
KeywordUsage AS (
    SELECT 
        kw.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword kw
    JOIN 
        movie_keyword mk ON kw.id = mk.keyword_id
    GROUP BY 
        kw.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    ra.actor_name,
    pm.movie_title,
    pm.production_year,
    ku.keyword,
    ku.movie_count
FROM 
    RankedActors ra
JOIN 
    PopularMovies pm ON ra.rank = 1
JOIN 
    KeywordUsage ku ON ku.movie_count > 2
WHERE 
    ra.person_id IN (
        SELECT person_id 
        FROM cast_info 
        WHERE movie_id IN (
            SELECT movie_id 
            FROM movie_keyword 
            WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword = ku.keyword)
        )
    )
ORDER BY 
    pm.production_year DESC, 
    ra.actor_name;
