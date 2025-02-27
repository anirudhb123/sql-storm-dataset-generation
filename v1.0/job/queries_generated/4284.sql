WITH Recursive_Actor_Movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
),
Company_Movie_Info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mn.id) AS num_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
Movie_Keyword_Count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT 
    ram.actor_name,
    ram.movie_title,
    ram.production_year,
    cm.num_companies,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    ram.rn
FROM Recursive_Actor_Movies ram
LEFT JOIN Company_Movie_Info cm ON ram.movie_id = cm.movie_id
LEFT JOIN Movie_Keyword_Count mk ON ram.movie_id = mk.movie_id
WHERE ram.rn <= 3
ORDER BY ram.actor_name, ram.production_year DESC;
