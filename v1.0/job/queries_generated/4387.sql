WITH MovieStats AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
GenreCount AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mk.keyword_id IS NOT NULL
    GROUP BY 
        mt.id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.company_count,
    gc.genre_count,
    CASE 
        WHEN ms.actor_count IS NULL THEN 'No Actors'
        WHEN ms.company_count IS NULL THEN 'No Companies'
        ELSE 'Available Data' 
    END AS data_availability
FROM 
    MovieStats ms
LEFT JOIN 
    GenreCount gc ON ms.movie_id = gc.movie_id
ORDER BY 
    ms.production_year DESC, 
    ms.actor_count DESC;
