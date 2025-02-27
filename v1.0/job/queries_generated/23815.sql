WITH Recursive_Actor_Film AS (
    SELECT 
        akn.id AS actor_id,
        akn.name AS actor_name,
        akn.person_id,
        at.id AS title_id,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY akn.person_id ORDER BY at.production_year DESC) AS film_rank
    FROM 
        aka_name akn
    JOIN 
        cast_info ci ON akn.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        akn.name IS NOT NULL
),
Actor_Info AS (
    SELECT 
        ra.actor_id,
        ra.actor_name,
        ra.movie_title,
        ra.production_year,
        (SELECT COUNT(*) 
         FROM cast_info ci2 
         WHERE ci2.person_id = ra.person_id 
         AND ci2.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year = ra.production_year)) AS co_stars_count,
        COUNT(DISTINCT mi.movie_id) AS total_movies,
        COALESCE(MAX(mi.info), 'No Information') AS latest_movie_info
    FROM 
        Recursive_Actor_Film ra
    LEFT JOIN 
        movie_info mi ON ra.title_id = mi.movie_id
    WHERE 
        ra.film_rank = 1
    GROUP BY 
        ra.actor_id, ra.actor_name, ra.movie_title, ra.production_year
),
Filtered_Actor AS (
    SELECT 
        ai.actor_id,
        ai.actor_name,
        ai.movie_title,
        ai.production_year,
        ai.co_stars_count,
        ai.total_movies,
        ai.latest_movie_info
    FROM 
        Actor_Info ai
    WHERE 
        ai.co_stars_count BETWEEN 1 AND 5
)
SELECT 
    fa.actor_id,
    fa.actor_name,
    fa.movie_title,
    fa.production_year,
    fa.co_stars_count,
    fa.total_movies,
    fa.latest_movie_info,
    CASE 
        WHEN fa.total_movies > 10 THEN 'Veteran Actor'
        WHEN fa.total_movies = 0 THEN 'Newcomer'
        ELSE 'Experienced Actor'
    END AS actor_experience,
    (SELECT 
            STRING_AGG(DISTINCT ct.kind, ', ') 
     FROM 
            movie_companies mc 
     JOIN 
            company_type ct ON mc.company_type_id = ct.id 
     WHERE 
            mc.movie_id = fa.title_id) AS companies_involved
FROM 
    Filtered_Actor fa
ORDER BY 
    fa.production_year DESC, fa.actor_name ASC;
