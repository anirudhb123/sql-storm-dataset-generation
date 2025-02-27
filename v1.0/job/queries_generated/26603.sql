WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN ci.person_role_id = rt.id THEN 1 ELSE 0 END), 0) AS total_actors,
        COALESCE(GROUP_CONCAT(DISTINCT a.name ORDER BY a.name), '') AS actor_names,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword), '') AS keywords
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.person_role_id = rt.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 -- Filtering for movies produced from year 2000 onwards
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_ranking AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_actors,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY total_actors DESC, title) AS actor_rank -- Ranking based on number of actors
    FROM 
        ranked_movies
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.total_actors,
    mr.actor_names,
    mr.keywords,
    CASE 
        WHEN mr.actor_rank <= 10 THEN 'Top 10'
        WHEN mr.actor_rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS rank_category
FROM 
    movie_ranking mr
ORDER BY 
    mr.actor_rank, mr.title;
