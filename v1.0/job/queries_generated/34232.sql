WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        a.surname_pcode,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id = (SELECT id FROM title WHERE title = 'Inception') -- Define starting movie

    UNION ALL

    SELECT 
        ci.person_id,
        a.name AS actor_name,
        a.surname_pcode,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
    WHERE 
        ah.level < 5  -- Limiting to 5 levels deep for hierarchy
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    STRING_AGG(DISTINCT title.title, ', ') AS titles,
    SUM(CASE WHEN mci.note IS NOT NULL THEN 1 ELSE 0 END) AS companies_with_notes,
    AVG(COALESCE(yi.info, 0)) AS avg_rating, 
    (SELECT COUNT(*) FROM keyword k WHERE k.id IN (SELECT mk.keyword_id FROM movie_keyword mk WHERE mk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id))) AS keyword_count
FROM 
    ActorHierarchy ah
LEFT JOIN 
    cast_info ci ON ah.person_id = ci.person_id
LEFT JOIN 
    title ON ci.movie_id = title.id
LEFT JOIN 
    movie_companies mci ON ci.movie_id = mci.movie_id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_idx yi ON ci.movie_id = yi.movie_id AND yi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Rating', 'Popularity')) 
WHERE 
    title.production_year >= 2010 
    AND title.production_year <= 2023
GROUP BY 
    ah.actor_name, ah.surname_pcode
HAVING 
    COUNT(DISTINCT ci.movie_id) > 3  -- Only include actors with more than 3 movies in this range
ORDER BY 
    movies_count DESC
LIMIT 10;
