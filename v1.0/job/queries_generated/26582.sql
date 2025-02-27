WITH ranked_movies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        COUNT(ci.person_role_id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY COUNT(ci.person_role_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, 
        at.title, 
        at.production_year, 
        ak.name
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        rm.role_count,
        mk.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON rm.id = mk.movie_id
    WHERE 
        rm.rank <= 3
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role_count,
    keywords
FROM 
    movie_details
ORDER BY 
    production_year DESC, 
    role_count DESC;
