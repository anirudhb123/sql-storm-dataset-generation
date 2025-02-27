
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
popular_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        num_cast_members
    FROM 
        movie_details
    WHERE 
        num_cast_members > (SELECT AVG(num_cast_members) FROM movie_details)
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)
SELECT 
    pm.title,
    pm.production_year,
    pm.num_cast_members,
    cmi.company_name,
    cmi.company_type,
    (SELECT COUNT(*) 
     FROM movie_info AS mi 
     WHERE mi.movie_id = pm.title_id 
       AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS rating_count,
    CASE 
        WHEN pm.num_cast_members IS NULL THEN 'No Cast'
        ELSE CAST(pm.num_cast_members AS VARCHAR)
    END AS cast_info
FROM 
    popular_movies AS pm
LEFT JOIN 
    company_movie_info AS cmi ON pm.title_id = cmi.movie_id
ORDER BY 
    pm.production_year DESC, 
    pm.num_cast_members DESC
LIMIT 50;
