
WITH Recursive_CTE AS (
    SELECT 
        ak.id AS person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS total_movies,
        MAX(t.production_year) AS latest_movie_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS rn
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    LEFT JOIN 
        aka_title t ON cc.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        ak.id, ak.name
),
Filtered_Actors AS (
    SELECT 
        person_id,
        actor_name,
        total_movies,
        latest_movie_year
    FROM 
        Recursive_CTE
    WHERE 
        total_movies > 5 AND latest_movie_year IS NOT NULL
),
Keyword_Movies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    fa.actor_name,
    fa.total_movies,
    fa.latest_movie_year,
    COALESCE(km.keywords, 'No Keywords') AS movie_keywords
FROM 
    Filtered_Actors fa
LEFT JOIN 
    cast_info ci ON fa.person_id = ci.person_id
LEFT JOIN 
    Keyword_Movies km ON ci.movie_id = km.movie_id
WHERE 
    fa.latest_movie_year > (SELECT AVG(latest_movie_year) FROM Filtered_Actors)
    OR EXISTS (
        SELECT 1
        FROM movie_info mi 
        WHERE mi.movie_id = ci.movie_id AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Box Office'
        ) AND mi.info LIKE '%million%'
    )
ORDER BY 
    fa.total_movies DESC, 
    fa.actor_name ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
