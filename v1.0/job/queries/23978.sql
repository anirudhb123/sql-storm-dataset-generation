
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
yearly_production AS (
    SELECT 
        production_year,
        SUM(actor_count) AS total_actors
    FROM 
        movie_details
    GROUP BY 
        production_year
),
keyword_usage AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.movie_id) > 1
),
highlights AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.actor_count,
        y.total_actors,
        ku.keyword,
        ku.keyword_count
    FROM 
        movie_details md
    JOIN 
        yearly_production y ON md.production_year = y.production_year
    LEFT JOIN 
        keyword_usage ku ON md.title_id = ku.movie_id
    WHERE 
        md.actor_count >= 5 AND
        (y.total_actors > 1000 OR ku.keyword IS NOT NULL)
    ORDER BY 
        md.production_year DESC, md.actor_count DESC
),
top_highlights AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        highlights
)
SELECT 
    th.title,
    th.production_year,
    th.actor_count,
    th.total_actors,
    th.keyword,
    th.keyword_count
FROM 
    top_highlights th
WHERE 
    th.rank <= 5
ORDER BY 
    th.production_year DESC, th.actor_count DESC;
