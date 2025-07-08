
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        MIN(CASE WHEN ci.person_role_id = 1 THEN ak.name ELSE NULL END) AS lead_actor
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    WHERE 
        t.production_year IS NOT NULL 
        AND (t.note IS NULL OR t.note NOT LIKE '%deleted%')
    GROUP BY 
        t.id, t.title, t.production_year
), ranked_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actors,
        keyword_count,
        lead_actor,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC, actors ASC) AS rank
    FROM 
        movie_details
), movie_info_detailed AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.actors,
        rm.lead_actor,
        COALESCE(mi.info, 'No additional info available') AS extra_info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON mi.movie_id = rm.title_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    mid.title_id,
    mid.title,
    mid.production_year,
    mid.actors,
    mid.lead_actor,
    mid.extra_info,
    CASE 
        WHEN mid.production_year < 2000 THEN 'Classic'
        WHEN mid.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mid.title_id AND mc.company_type_id IS NOT NULL) AS production_companies
FROM 
    movie_info_detailed mid
WHERE 
    mid.extra_info IS NOT NULL
    AND mid.title ILIKE '%adventure%'
ORDER BY 
    mid.production_year DESC; 
