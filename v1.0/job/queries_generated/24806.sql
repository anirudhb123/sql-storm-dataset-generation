WITH movie_and_actors AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.note AS role_note,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY t.id) AS total_actors
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL 
        AND a.name IS NOT NULL 
        AND c.nr_order IS NOT NULL
), 
actor_performance AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        actor_rank,
        total_actors,
        CASE 
            WHEN actor_rank = 1 THEN 'Lead Actor'
            WHEN actor_rank <= 3 THEN 'Supporting Actor'
            ELSE 'Background Actor' 
        END AS actor_role
    FROM 
        movie_and_actors
), 
high_profile_movies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS unique_actors,
        STRING_AGG(DISTINCT a.actor_name, ', ') FILTER (WHERE a.actor_rank <= 3) AS top_actors
    FROM 
        actor_performance a
    GROUP BY 
        movie_title, production_year
    HAVING 
        COUNT(DISTINCT actor_name) >= 10
), 
suffix_year_filter AS (
    SELECT 
        movie_title,
        production_year,
        top_actors,
        CASE 
            WHEN production_year % 2 = 0 THEN 'Even Year'
            ELSE 'Odd Year' 
        END AS year_category
    FROM 
        high_profile_movies
), 
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        top_actors,
        year_category,
        ROW_NUMBER() OVER (PARTITION BY year_category ORDER BY production_year DESC) AS ranking
    FROM 
        suffix_year_filter
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.top_actors,
    rm.year_category,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
    CASE 
        WHEN rm.ranking <= 5 THEN 'Top 5 Movies in ' || rm.year_category 
        ELSE 'Movies in ' || rm.year_category 
    END AS ranking_label
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT mt.id FROM aka_title mt WHERE mt.title = rm.movie_title LIMIT 1)
WHERE 
    rm.year_category = 'Even Year'
ORDER BY 
    rm.production_year DESC, 
    ranking;
