WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.role_id) AS role_ids,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        a.imdb_index,
        ARRAY_AGG(DISTINCT m.movie_id) AS movie_ids,
        ARRAY_AGG(DISTINCT m.title) AS movies
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        title m ON ci.movie_id = m.id
    GROUP BY 
        a.id, a.name, a.imdb_index
),
company_count AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        movie_details m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ad.name AS actor_name,
    ad.imdb_index AS actor_imdb_index,
    cc.company_count,
    md.role_ids,
    md.keywords
FROM 
    movie_details md
JOIN 
    company_count cc ON md.movie_id = cc.movie_id
JOIN 
    actor_details ad ON md.role_ids && ad.movie_ids
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.title;

This SQL query does the following:

1. **With Clauses**: It utilizes Common Table Expressions (CTEs) to define temporary result sets for easier readability.
   - `movie_details`: Collects movies, their production years, unique role IDs, and associated keywords.
   - `actor_details`: Gathers actor information, including total movies they are linked with.
   - `company_count`: Counts distinct companies associated with each movie to reflect production involvement.

2. **Main Query**: Joins the data collected in CTEs to provide a comprehensive view of movies, including their titles, actor information, the number of production companies involved, roles associated with actors, and keywords.

3. **Filtering and Ordering**: Filters movies produced between 2000 and 2023, ordering the results by production year (desc) and title to make the output structured and informative.
