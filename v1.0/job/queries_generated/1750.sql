WITH ranked_titles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
movie_cast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        a.person_id, 
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
), 
movie_information AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(mi.info || ' (' || it.info || ')', ', ') AS movie_details
    FROM 
        movie_info m
    JOIN 
        info_type it ON it.id = m.info_type_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title, 
    rt.production_year, 
    mc.actor_name, 
    mi.movie_details,
    COALESCE(bk.budget, 'Unknown') AS budget,
    COALESCE(p.title, 'N/A') AS previous_movie
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_cast mc ON mc.movie_id = rt.id
LEFT JOIN 
    movie_information mi ON mi.movie_id = rt.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         SUM(CASE WHEN note ILIKE '%budget%' THEN CAST(SUBSTRING(note FROM '(\d+)') AS INTEGER) END) AS budget
     FROM 
         movie_companies
     GROUP BY 
         movie_id) bk ON bk.movie_id = rt.id
LEFT JOIN 
    (SELECT 
         m1.title, 
         m2.title AS previous_title
     FROM 
         aka_title m1
     JOIN 
         aka_title m2 ON m1.production_year = m2.production_year AND m1.id < m2.id) p ON p.title = rt.title
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    mc.actor_order ASC;
