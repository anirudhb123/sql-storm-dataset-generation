WITH recursive movie_data AS (
    SELECT 
        mt.title AS movie_title, 
        mt.production_year, 
        ka.name AS actor_name, 
        ka.surname_pcode, 
        mk.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ka.name) AS actor_rank,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY mt.id) AS total_companies,
        (SELECT COUNT(*) FROM movie_companies mcc WHERE mcc.movie_id = mt.id AND mcc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributor_count
    FROM 
        aka_title mt 
        INNER JOIN cast_info ci ON ci.movie_id = mt.id 
        LEFT JOIN aka_name ka ON ka.person_id = ci.person_id 
        LEFT JOIN movie_keyword mk ON mk.movie_id = mt.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020 
        AND ci.nr_order < 5 
),

filtered_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name, 
        surname_pcode, 
        keyword,
        actor_rank, 
        total_companies,
        distributor_count
    FROM 
        movie_data
    WHERE 
        total_companies > 2 
        AND distributor_count IS NOT NULL
        AND keyword IS NOT NULL
        AND production_year % 2 = 0  -- Only consider even production years
),

grouped_movies AS (
    SELECT 
        production_year, 
        COUNT(DISTINCT movie_title) AS count_movies, 
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        MAX(actor_rank) AS max_actors,
        COUNT(DISTINCT surname_pcode) AS unique_surnames
    FROM 
        filtered_movies
    GROUP BY 
        production_year
)

SELECT 
    production_year,
    count_movies,
    keywords,
    max_actors,
    unique_surnames,
    CASE 
        WHEN count_movies > 10 THEN 'Many Movies'
        WHEN count_movies BETWEEN 5 AND 10 THEN 'Few Movies'
        ELSE 'Single or No Movies'
    END AS movie_count_category
FROM 
    grouped_movies
ORDER BY 
    production_year DESC;
