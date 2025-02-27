WITH title_data AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        kt.kind AS kind_name,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, kt.kind
),
actor_data AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.name
),
keyword_data AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
)

SELECT 
    td.title_id,
    td.title,
    td.production_year,
    td.kind_name,
    td.company_count,
    ak.actor_name,
    ak.movies_count,
    ak.movies_titles,
    kd.keywords
FROM 
    title_data td
LEFT JOIN 
    actor_data ak ON td.title_id = ak.movies_count 
    -- Assuming we're joining on the count of movies to find common actors (for illustrative purpose)
LEFT JOIN 
    keyword_data kd ON td.title_id = kd.movie_id
WHERE 
    td.production_year BETWEEN 2000 AND 2020
ORDER BY 
    td.production_year DESC, 
    td.title;
