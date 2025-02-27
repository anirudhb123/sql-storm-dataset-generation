WITH RankedActors AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(ci.movie_id) DESC) AS movie_count_rank
    FROM
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),

PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title m
    INNER JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),

AwardWinningFilms AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        gai.info AS award_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    LEFT JOIN 
        info_type gai ON mi.info_type_id = gai.id
    WHERE 
        LOWER(gai.info) LIKE '%award%'
)

SELECT 
    pa.actor_name,
    pm.movie_title,
    pm.production_year,
    awf.award_info
FROM 
    RankedActors pa
JOIN 
    cast_info ci ON pa.person_id = ci.person_id
JOIN 
    PopularMovies pm ON ci.movie_id = pm.movie_id
LEFT JOIN 
    AwardWinningFilms awf ON pm.movie_id = awf.movie_id
WHERE 
    pa.movie_count_rank <= 5
ORDER BY 
    pa.actor_name, pm.production_year DESC;
