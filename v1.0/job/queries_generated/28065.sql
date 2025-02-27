WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        m.id, m.title, m.production_year
), high_actor_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_count,
        aka_names,
        RANK() OVER (ORDER BY actor_count DESC) AS actor_rank
    FROM 
        ranked_movies
    WHERE 
        actor_count >= 3  -- Filter for movies with 3 or more actors
)
SELECT 
    ham.movie_title,
    ham.production_year,
    ham.actor_count,
    ham.aka_names,
    mtype.kind AS company_type,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
FROM 
    high_actor_movies ham
JOIN 
    movie_companies mc ON ham.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mtype ON mc.company_type_id = mtype.id
GROUP BY 
    ham.movie_id, ham.movie_title, ham.production_year, ham.actor_count, ham.aka_names, mtype.kind
ORDER BY 
    ham.actor_count DESC, ham.production_year DESC
LIMIT 10;  -- Limit to top 10 results
