WITH MovieKeywordCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        k.keyword,
        k.phonetic_code
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
),
TopActorCTE AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        a.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    mt.title AS movie_title,
    mk.keyword AS movie_keyword,
    a.actor_name,
    COUNT(DISTINCT ci.movie_id) AS shared_movie_count
FROM 
    MovieKeywordCTE mk
JOIN 
    complete_cast cc ON mk.movie_id = cc.movie_id
JOIN 
    TopActorCTE a ON cc.subject_id = a.actor_name
JOIN 
    cast_info ci ON ci.movie_id = mk.movie_id AND ci.person_role_id = a.actor_name
WHERE 
    mk.phonetic_code IS NOT NULL
GROUP BY 
    mt.title, mk.keyword, a.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 1
ORDER BY 
    shared_movie_count DESC, mk.keyword, mt.title;
