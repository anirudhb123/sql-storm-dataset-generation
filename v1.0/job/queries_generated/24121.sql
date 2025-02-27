WITH Recursive_Actors AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(ci.movie_id) DESC) AS rn
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
), 
Best_Actors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        Recursive_Actors
    WHERE 
        rn <= 5
),
Movie_Keywords AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    b.actor_name,
    b.movie_count,
    m.title,
    m.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        ELSE m.production_year::TEXT 
     END) as production_year_info,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = m.id AND mi.info_type_id = 3
    ) AS trivia_count
FROM 
    Best_Actors b
LEFT JOIN 
    cast_info ci ON b.actor_name = (SELECT ak.name FROM aka_name ak WHERE ak.person_id = ci.person_id)
LEFT JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    Movie_Keywords mk ON m.id = mk.movie_id
WHERE 
    (m.production_year >= 2000 OR b.movie_count > 3)
    AND b.movie_count IS NOT NULL
ORDER BY 
    b.movie_count DESC, 
    m.production_year_info DESC NULLS LAST;
