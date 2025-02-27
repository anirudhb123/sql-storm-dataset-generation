WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        c.role_id,
        c.nr_order,
        mcn.name AS company_name,
        kt.keyword AS keyword_used
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name mcn ON mc.company_id = mcn.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        t.production_year >= 1990
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
actor_statistics AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies,
        STRING_AGG(DISTINCT movie_title, ', ') AS movie_list,
        MIN(production_year) AS first_year,
        MAX(production_year) AS last_year
    FROM 
        movie_details
    GROUP BY 
        actor_name
),
keyword_statistics AS (
    SELECT 
        keyword_used,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        movie_details
    GROUP BY 
        keyword_used
)
SELECT 
    a.actor_name,
    a.total_movies,
    a.movie_list,
    a.first_year,
    a.last_year,
    k.keyword_used,
    k.movie_count
FROM 
    actor_statistics a
LEFT JOIN 
    keyword_statistics k ON a.total_movies > 5
ORDER BY 
    a.total_movies DESC, 
    a.first_year ASC;
