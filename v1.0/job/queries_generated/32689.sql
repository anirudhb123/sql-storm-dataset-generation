WITH RECURSIVE Movie_CTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mc.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        Movie_CTE mc ON ml.movie_id = mc.movie_id
    WHERE 
        mc.level < 3
), 
Title_Cast AS (
    SELECT 
        at.title,
        at.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        at.id
), 
Movie_Info AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_details
    FROM 
        movie_info mi 
    JOIN 
        aka_title at ON mi.movie_id = at.id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')
    GROUP BY 
        mi.movie_id
), 
All_Movies AS (
    SELECT 
        m.movie_id,
        m.title, 
        m.production_year, 
        COALESCE(t.actors, '{}') AS actors,
        COALESCE(i.movie_details, '') AS info
    FROM 
        Movie_CTE m
    LEFT JOIN 
        Title_Cast t ON m.title = t.title AND m.production_year = t.production_year
    LEFT JOIN 
        Movie_Info i ON m.movie_id = i.movie_id
)
SELECT 
    am.title,
    am.production_year,
    am.actors,
    am.info,
    CASE 
        WHEN am.info IS NULL OR am.info = '' THEN 'No Information Available'
        ELSE 'Information Available'
    END AS info_status,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY am.movie_id) AS total_actors
FROM 
    All_Movies am
LEFT JOIN 
    cast_info ci ON am.movie_id = ci.movie_id
ORDER BY 
    am.production_year DESC, 
    am.title;
