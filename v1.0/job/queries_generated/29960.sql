WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        a.name AS director_name,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        name a ON ak.person_id = a.imdb_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND c.country_code = 'USA'
        AND ak.name IS NOT NULL
),
actor_count AS (
    SELECT 
        actor_index,
        COUNT(*) AS total_movies
    FROM 
        movie_details
    GROUP BY 
        actor_index
),
ranked_actors AS (
    SELECT 
        actor_name,
        total_movies,
        ROW_NUMBER() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        movie_details md
    JOIN 
        actor_count ac ON md.actor_index = ac.actor_index
)
SELECT 
    rd.actor_name,
    rd.total_movies,
    rd.rank,
    md.movie_title,
    md.production_year,
    md.company_type,
    md.director_name,
    md.movie_keyword
FROM 
    ranked_actors rd
JOIN 
    movie_details md ON md.actor_name = rd.actor_name
WHERE 
    rd.rank <= 10
ORDER BY 
    rd.rank, md.production_year DESC;
