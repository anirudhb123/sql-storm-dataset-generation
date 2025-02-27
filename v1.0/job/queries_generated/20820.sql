WITH movie_actors AS (
    SELECT 
        a.id AS actor_id, 
        a.name as actor_name, 
        c.movie_id, 
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM 
        aka_name a 
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL 
        AND t.production_year >= 1990
),

actor_movie_counts AS (
    SELECT 
        actor_id, 
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_actors
    GROUP BY 
        actor_id
),

top_actors AS (
    SELECT 
        ma.actor_id, 
        ma.actor_name, 
        amc.movie_count,
        RANK() OVER (ORDER BY amc.movie_count DESC) AS rank
    FROM 
        movie_actors ma
    JOIN 
        actor_movie_counts amc ON ma.actor_id = amc.actor_id
    WHERE 
        amc.movie_count > 5
),

title_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt 
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),

movies_info AS (
    SELECT 
        t.title, 
        t.production_year,
        c.kind AS company_type,
        CASE 
            WHEN p.info IS NOT NULL THEN p.info 
            ELSE 'N/A' 
        END AS director_info
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
    LEFT JOIN 
        person_info p ON mi.id = p.id

)

SELECT 
    ta.actor_name,
    ta.movie_count,
    mi.title,
    mi.production_year,
    tk.keywords
FROM 
    top_actors ta
JOIN 
    movie_actors ma ON ta.actor_id = ma.actor_id
JOIN 
    movies_info mi ON ma.movie_id = mi.movie_id
LEFT JOIN 
    title_keywords tk ON mi.title = tk.title
WHERE 
    mi.production_year BETWEEN 2000 AND 2020
    AND (tk.keywords IS NOT NULL OR mi.director_info = 'N/A')
ORDER BY 
    ta.rank, mi.production_year DESC
LIMIT 10;


