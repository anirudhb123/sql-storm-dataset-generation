
WITH recursive actor_movies AS (
    SELECT 
        ca.person_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER(PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM
        cast_info ca
    JOIN
        aka_title at ON ca.movie_id = at.id
    WHERE
        at.production_year IS NOT NULL
), 
unique_movies AS (
    SELECT 
        person_id,
        COUNT(DISTINCT title) AS unique_movie_count
    FROM 
        actor_movies
    WHERE 
        movie_rank <= 5
    GROUP BY 
        person_id
), 
aggregate_info AS (
    SELECT 
        ak.name,
        um.unique_movie_count,
        SUM(CASE WHEN at.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count,
        LISTAGG(DISTINCT at.title, ', ') WITHIN GROUP (ORDER BY at.title) AS title_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        unique_movies um ON ak.person_id = um.person_id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
    GROUP BY 
        ak.name, um.unique_movie_count
), 
ranked_actors AS (
    SELECT 
        name,
        unique_movie_count,
        pre_2000_count,
        title_list,
        RANK() OVER (ORDER BY unique_movie_count DESC) AS actor_rank
    FROM 
        aggregate_info
)
SELECT 
    ra.name,
    ra.unique_movie_count,
    ra.pre_2000_count,
    ra.title_list,
    CASE 
        WHEN ra.pre_2000_count > 0 THEN 'Veteran Actor' 
        ELSE 'Newcomer' 
    END AS actor_category
FROM 
    ranked_actors ra
WHERE 
    ra.actor_rank <= 10
ORDER BY 
    actor_category, unique_movie_count DESC
LIMIT 10;
