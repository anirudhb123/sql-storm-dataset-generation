WITH actor_titles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        t.imdb_index AS movie_index,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        ci.note IS NULL
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(kw.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        a.actor_name,
        mt.title,
        mt.production_year,
        mt.keywords,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        actor_titles a
    JOIN 
        movies_with_keywords mt ON a.movie_title = mt.title AND a.production_year = mt.production_year
    JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        a.title_rank = 1  
    GROUP BY 
        a.actor_name, mt.title, mt.production_year, mt.keywords
)
SELECT 
    actor_name,
    title,
    production_year,
    keywords,
    total_cast
FROM 
    top_movies
ORDER BY 
    production_year DESC,
    actor_name;