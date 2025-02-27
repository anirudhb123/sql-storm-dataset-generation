WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY LENGTH(at.title) DESC) AS title_length_rank
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        aka_name ak ON mk.keyword_id = ak.id
    WHERE 
        at.production_year >= 2000 AND 
        ak.name IS NOT NULL
),
highly_ranked_actors AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count
    FROM 
        ranked_movies
    WHERE 
        title_length_rank <= 3
    GROUP BY 
        actor_name
),
top_actors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        highly_ranked_actors
),
movies_info AS (
    SELECT 
        at.title,
        ak.name AS actor_name,
        at.production_year,
        mi.info AS movie_info
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_info mi ON at.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
)
SELECT 
    t.actor_name,
    t.movie_count,
    COUNT(DISTINCT m.title) AS unique_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT m.movie_info, ' | ') AS movie_details
FROM 
    top_actors t
JOIN 
    movies_info m ON t.actor_name = m.actor_name
GROUP BY 
    t.actor_name, 
    t.movie_count
ORDER BY 
    t.actor_rank;
