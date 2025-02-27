WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT cc.id) AS num_movies_co_starred
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    LEFT JOIN 
        aka_title at ON cc.movie_id = at.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, ak.person_id
), 
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
filtered_titles AS (
    SELECT 
        at.id AS title_id, 
        at.title, 
        at.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movies_with_keywords k ON at.id = k.movie_id
    WHERE 
        at.production_year >= 2000
        AND (LOWER(at.title) NOT LIKE '%sequel%' OR at.title IS NULL)
)
SELECT 
    ah.actor_name,
    ft.title,
    ft.production_year,
    ah.num_movies_co_starred,
    ROW_NUMBER() OVER (PARTITION BY ah.actor_name ORDER BY ft.production_year DESC) AS rank_by_year,
    CASE 
        WHEN ft.keywords IS NOT NULL THEN ft.keywords 
        ELSE 'No associated keywords found'
    END AS keywords_associated,
    CASE 
        WHEN ft.production_year IS NULL THEN 'Unknown Year' 
        ELSE CONCAT('Released in ', ft.production_year) 
    END AS year_info
FROM 
    actor_hierarchy ah
LEFT JOIN 
    filtered_titles ft ON ah.num_movies_co_starred > 2
WHERE 
    ft.title IS NOT NULL
ORDER BY 
    ah.actor_name, ft.production_year DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
