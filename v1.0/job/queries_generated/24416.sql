WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
        AND mt.production_year > 2000
),
ActorCTE AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT at.title, ', ') AS movies_list
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        ak.person_id, ak.name
)
SELECT 
    m.movie_id,
    m.title,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    a.total_movies,
    m.production_year,
    CASE 
        WHEN m.production_year IS NOT NULL THEN 
            (SELECT COUNT(*) FROM aka_title at WHERE at.production_year = m.production_year)
        ELSE 
            0
    END AS same_year_movies,
    RANK() OVER (ORDER BY m.production_year) AS movie_rank,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info='MPAA Rating')) AS rating_info_count
FROM 
    MovieCTE m
LEFT JOIN 
    ActorCTE a ON a.total_movies > 5 OR a.person_id IS NULL
WHERE 
    (m.production_year IN (SELECT DISTINCT production_year FROM aka_title WHERE production_year < 2020))
    OR (m.production_year IS NULL)
ORDER BY 
    m.production_year DESC,
    a.total_movies DESC NULLS LAST;
