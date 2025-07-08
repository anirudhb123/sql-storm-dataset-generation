
WITH RecursiveActorMovies AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
ComplicatedInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        CASE 
            WHEN mi.info_count > 3 THEN 'Rich Info'
            WHEN mi.info_count IS NULL THEN 'No Info'
            ELSE 'Standard Info'
        END AS info_category,
        COALESCE(mi.info_details, 'N/A') AS details
    FROM 
        aka_title m
    LEFT JOIN 
        MovieInfo mi ON m.movie_id = mi.movie_id
)
SELECT 
    ram.actor_name,
    ram.movie_title,
    ram.production_year,
    ci.info_category,
    ci.details,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    MAX(CASE WHEN mc.note IS NULL THEN 'No Note' ELSE mc.note END) AS production_note
FROM 
    RecursiveActorMovies ram
LEFT JOIN 
    complete_cast cc ON ram.person_id = cc.subject_id
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    ComplicatedInfo ci ON ram.movie_title = ci.title
WHERE 
    ram.rn = 1
    AND ram.production_year >= 2000
GROUP BY 
    ram.actor_name, ram.movie_title, ram.production_year, ci.info_category, ci.details
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    ram.production_year DESC, ram.actor_name;
