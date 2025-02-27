WITH ActorData AS (
    SELECT 
        akn.name AS actor_name,
        akn.person_id,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT tt.title, ', ') AS titles,
        SUM(CASE WHEN tt.production_year IS NOT NULL THEN tt.production_year ELSE 0 END) AS total_production_year,
        AVG(COALESCE(tt.production_year, 0)) AS avg_production_year
    FROM aka_name akn 
    JOIN cast_info ci ON akn.person_id = ci.person_id
    JOIN aka_title tt ON ci.movie_id = tt.movie_id
    WHERE akn.name IS NOT NULL
    GROUP BY akn.name, akn.person_id
),
MovieData AS (
    SELECT 
        tt.title AS movie_title,
        tt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN mr.info IS NOT NULL THEN 1 ELSE 0 END) AS has_movie_info
    FROM aka_title tt 
    LEFT JOIN cast_info ci ON tt.movie_id = ci.movie_id
    LEFT JOIN movie_info mr ON tt.movie_id = mr.movie_id
    GROUP BY tt.title, tt.production_year
)

SELECT 
    ad.actor_name,
    ad.movie_count,
    ad.titles,
    ad.total_production_year,
    ad.avg_production_year,
    md.movie_title,
    md.production_year,
    md.total_actors,
    md.has_movie_info,
    CASE
        WHEN ad.movie_count > md.total_actors THEN 'More Movies than Actors'
        WHEN ad.movie_count < md.total_actors THEN 'Fewer Movies than Actors'
        ELSE 'Equal Movies and Actors'
    END AS movie_actor_comparison,
    (SELECT MAX(ad2.movie_count) 
     FROM ActorData ad2 
     WHERE ad2.person_id <> ad.person_id) AS max_other_actor_movies
FROM ActorData ad 
FULL OUTER JOIN MovieData md ON ad.movie_count = md.total_actors
WHERE (ad.total_production_year / NULLIF(ad.movie_count, 0)) > 2000 OR md.has_movie_info > 0
ORDER BY ad.avg_production_year DESC NULLS LAST, md.production_year ASC;
