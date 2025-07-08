
WITH RECURSIVE CTE_Movies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        c.depth + 1
    FROM 
        aka_title m
    JOIN 
        CTE_Movies c ON m.episode_of_id = c.movie_id
),
Ranked_Movies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        CTE_Movies m
),
Movie_Keywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
Detailed_Cast AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count, 
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
Final_Report AS (
    SELECT 
        r.movie_id, 
        r.title,
        r.production_year,
        r.year_rank,
        d.actor_count,
        d.actor_names,
        mk.keyword
    FROM 
        Ranked_Movies r
    LEFT JOIN 
        Detailed_Cast d ON r.movie_id = d.movie_id
    LEFT JOIN 
        Movie_Keywords mk ON r.movie_id = mk.movie_id
    WHERE 
        d.actor_count IS NOT NULL
),
Aggregated_Report AS (
    SELECT 
        title, 
        production_year, 
        COUNT(DISTINCT actor_names) AS unique_actor_count,
        LISTAGG(DISTINCT keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
    FROM 
        Final_Report
    GROUP BY 
        title, 
        production_year
)
SELECT 
    a.title, 
    a.production_year, 
    COALESCE(a.unique_actor_count, 0) AS unique_actor_count,
    COALESCE(a.keywords, 'No keywords available') AS keywords
FROM 
    Aggregated_Report a
WHERE 
    a.production_year BETWEEN 2000 AND 2023
ORDER BY 
    a.production_year DESC, 
    a.title;
