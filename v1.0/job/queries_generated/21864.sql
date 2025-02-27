WITH Recursive_CTE AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        aka_name.name AS actor_name,
        COUNT(DISTINCT cast_info.person_id) OVER (PARTITION BY title.id) AS total_actors,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_name.name) AS actor_rank,
        COALESCE(movie_info.info, 'No Info') AS movie_info
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id 
        AND movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    WHERE 
        title.production_year IS NOT NULL
    AND 
        aka_name.name IS NOT NULL
    
    UNION
    
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        'Unknown Actor' AS actor_name,
        COUNT(DISTINCT cast_info.person_id) OVER (PARTITION BY title.id) AS total_actors,
        NULL AS actor_rank,
        'No Info' AS movie_info
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    WHERE 
        title.id NOT IN (SELECT movie_id FROM cast_info)
    
), Filtered_CTE AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name,
        total_actors,
        actor_rank,
        movie_info,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_actors DESC) AS yearly_rank
    FROM 
        Recursive_CTE
    WHERE 
        (actor_name IS NOT NULL OR actor_name = 'Unknown Actor') AND total_actors > 0
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.total_actors,
    f.actor_rank,
    f.movie_info,
    f.yearly_rank
FROM 
    Filtered_CTE f
WHERE 
    f.yearly_rank <= 10
ORDER BY 
    f.production_year DESC, 
    f.total_actors DESC;
