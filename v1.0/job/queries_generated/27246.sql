WITH actor_movies AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles,
        STRING_AGG(DISTINCT t.production_year::text, ', ') AS production_years
    FROM 
        cast_info ca
    JOIN 
        title t ON ca.movie_id = t.id
    GROUP BY 
        ca.person_id
),

award_winning_companies AS (
    SELECT 
        mc.company_id,
        cn.name AS company_name,
        STRING_AGG(DISTINCT t.title, ', ') AS award_winning_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        title t ON mc.movie_id = t.id
    WHERE 
        t.production_year >= 2000 -- Assume awards started from 2000
        AND t.id IN (SELECT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Awards'))
    GROUP BY 
        mc.company_id, cn.name
),

high_profile_actors AS (
    SELECT
        a.id AS actor_id,
        a.name,
        am.movie_count,
        ac.company_count,
        ROW_NUMBER() OVER (ORDER BY am.movie_count DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        actor_movies am ON a.person_id = am.person_id
    JOIN 
        (SELECT 
            ca.person_id,
            COUNT(DISTINCT mc.company_id) AS company_count
         FROM 
            cast_info ca
         JOIN 
            movie_companies mc ON ca.movie_id = mc.movie_id
         GROUP BY 
            ca.person_id) ac ON a.person_id = ac.person_id
)

SELECT 
    ha.actor_id,
    ha.name,
    ha.movie_count,
    ha.company_count,
    awc.company_name,
    awc.award_winning_movies
FROM 
    high_profile_actors ha
LEFT JOIN 
    award_winning_companies awc ON ha.company_count > 0
WHERE 
    ha.rank <= 10
ORDER BY 
    ha.movie_count DESC;
