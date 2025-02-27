WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        CASE 
            WHEN mt.production_year IS NULL THEN 'N/A'
            WHEN mt.production_year < 2000 THEN 'Pre-2000'
            ELSE 'Post-2000' 
        END AS era
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        'Continued' AS company_type,
        'Unknown' AS era
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')
),
actor_aggregates AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_role_id
    GROUP BY 
        ak.name
),
ranked_movies AS (
    SELECT 
        mh.title,
        mh.production_year,
        mh.company_type,
        mh.era,
        ROW_NUMBER() OVER (PARTITION BY mh.era ORDER BY mh.production_year DESC) AS production_rank
    FROM 
        movie_hierarchy mh
),
final_selection AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.company_type,
        rm.era,
        aa.actor_name,
        aa.movie_count,
        aa.note_count,
        RANK() OVER (PARTITION BY rm.era ORDER BY aa.movie_count DESC) AS actor_rank
    FROM 
        ranked_movies rm
    JOIN 
        actor_aggregates aa ON rm.title = aa.actor_name
    WHERE 
        rm.production_rank <= 10 AND aa.note_count > 0
)
SELECT 
    fs.title,
    fs.production_year,
    fs.company_type,
    fs.era,
    fs.actor_name,
    fs.movie_count,
    fs.note_count
FROM 
    final_selection fs
WHERE 
    fs.actor_rank <= 5 OR (fs.company_type = 'Distribution' AND fs.note_count > 2)
ORDER BY 
    fs.production_year DESC, fs.note_count DESC;