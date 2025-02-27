WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.name AS actor_name,
        c.role_id,
        CASE 
            WHEN c.note IS NOT NULL AND c.note <> '' THEN c.note 
            ELSE 'No Note' 
        END AS role_note,
        mk.keyword
    FROM ranked_movies rm
    LEFT JOIN cast_info c ON rm.movie_id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.role_note,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
FROM movie_details md
WHERE 
    md.production_year > 2000 
    AND (md.role_note IS NOT NULL OR md.actor_name IS NULL)
GROUP BY 
    md.movie_id, md.title, md.production_year, md.actor_name, md.role_note
HAVING 
    COUNT(md.keyword) > 1
ORDER BY 
    md.production_year DESC, md.title
LIMIT 50;
