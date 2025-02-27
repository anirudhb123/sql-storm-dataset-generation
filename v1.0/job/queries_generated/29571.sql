WITH MovieRoleCounts AS (
    SELECT 
        att.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title att
    JOIN 
        cast_info ci ON att.movie_id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        att.title
),
MovieAggregateInfo AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
        COALESCE(mic.info, 'No Info') AS movie_info
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mic ON mt.movie_id = mic.movie_id
    WHERE 
        mt.production_year >= 2000
)
SELECT 
    mac.movie_title,
    mac.production_year,
    mac.movie_keyword,
    mac.movie_info,
    rc.actor_count,
    rc.actor_names
FROM 
    MovieAggregateInfo mac
JOIN 
    MovieRoleCounts rc ON mac.movie_title = rc.movie_title
WHERE 
    rc.actor_count > 5
ORDER BY 
    mac.production_year DESC;
