WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS year_rank
    FROM 
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE 'feature%')
),
actor_casts AS (
    SELECT 
        c.person_id,
        c.movie_id,
        ra.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ra ON c.person_id = ra.person_id
),
full_cast AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ac.actor_name,
        ac.actor_rank
    FROM 
        ranked_titles rt
    LEFT JOIN 
        actor_casts ac ON rt.title_id = ac.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fc.title AS movie_title,
    fc.production_year,
    COALESCE(fc.actor_name, 'No Actor') AS actor_name,
    COALESCE(fc.actor_rank::text, 'Not Ranked') AS actor_rank,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    full_cast fc
LEFT OUTER JOIN 
    movie_keywords mk ON fc.title_id = mk.movie_id
WHERE 
    fc.year_rank <= 10 AND 
    (fc.actor_rank IS NULL OR fc.actor_rank <= 3)
ORDER BY 
    fc.production_year DESC,
    fc.title ASC;
This SQL query generates a comprehensive list of selected movies alongside their top 3 actors if they exist, sorted by production year and title. It incorporates CTEs, window functions, outer joins, and ensures that NULL values are handled gracefully with COALESCE. The keywords associated with each movie are aggregated, providing a rich dataset for performance benchmarking.
