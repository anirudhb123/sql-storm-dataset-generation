
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order ASC) AS actor_order
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        LISTAGG(actor_name, ', ') WITHIN GROUP (ORDER BY actor_order) AS actor_list,
        COUNT(*) AS total_actors,
        MAX(actor_order) AS highest_actor_order
    FROM 
        movie_details
    GROUP BY 
        movie_id, title, production_year
),
filtered_movies AS (
    SELECT 
        *,
        CASE 
            WHEN total_actors = 0 THEN 'No Actors'
            WHEN total_actors > 5 THEN 'Ensemble Cast'
            ELSE 'Few Actors'
        END AS cast_size_description
    FROM 
        ranked_movies
    WHERE 
        production_year BETWEEN 2000 AND 2023
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_list,
    fm.total_actors,
    fm.highest_actor_order,
    fm.cast_size_description,
    COALESCE((SELECT COUNT(*) 
              FROM complete_cast cc 
              WHERE cc.movie_id = fm.movie_id AND cc.status_id = 1), 0) AS complete_cast_count,
    CASE
        WHEN fm.highest_actor_order IS NULL THEN 'No Information'
        WHEN fm.highest_actor_order <= 3 THEN 'Limited Characters'
        WHEN fm.highest_actor_order <= 10 THEN 'Moderate Characters'
        ELSE 'Rich Character Gallery'
    END AS character_gallery_description
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    mi.info IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.total_actors DESC, fm.title
LIMIT 50;
