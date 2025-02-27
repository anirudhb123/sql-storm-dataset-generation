WITH movie_actor_counts AS (
    SELECT 
        a.id AS actor_id,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id
),
top_actors AS (
    SELECT 
        actor_id 
    FROM 
        movie_actor_counts
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
actor_movies AS (
    SELECT 
        a.id AS actor_id,
        t.title AS movie_title,
        t.production_year,
        t.imdb_index AS imdb_title_index
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        a.id IN (SELECT actor_id FROM top_actors)
),
actor_movie_info AS (
    SELECT 
        am.actor_id,
        am.movie_title,
        am.production_year,
        am.imdb_title_index,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM 
        actor_movies am
    LEFT JOIN 
        movie_keyword mk ON am.imdb_title_index = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON am.imdb_title_index = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        am.actor_id, am.movie_title, am.production_year, am.imdb_title_index
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    ami.movie_title,
    ami.production_year,
    ami.keywords,
    ami.company_types
FROM 
    aka_name a
JOIN 
    actor_movie_info ami ON a.id = ami.actor_id
ORDER BY 
    ami.production_year DESC, 
    ami.movie_title;
