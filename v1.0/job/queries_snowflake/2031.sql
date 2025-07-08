WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_in_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),

movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(mc.company_id), 0) AS total_companies,
        COUNT(DISTINCT ki.keyword) AS total_keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),

actors_in_movies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT a.id) AS total_actors
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_companies,
    md.total_keywords,
    COALESCE(a.total_actors, 0) AS total_actors,
    CASE 
        WHEN md.production_year >= 2000 THEN 'Modern'
        ELSE 'Classic' 
    END AS movie_era
FROM 
    movie_details md
LEFT JOIN 
    actors_in_movies a ON md.movie_id = a.movie_id
WHERE 
    md.total_companies > 0
ORDER BY 
    md.production_year DESC, md.title;
