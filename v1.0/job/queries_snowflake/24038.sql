
WITH Recursive_Actor_Titles AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY ak.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    INNER JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
Company_Movie_Stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
Filtered_Movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(cms.company_count, 0) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        Company_Movie_Stats cms ON mt.id = cms.movie_id
    WHERE 
        mt.production_year > 2000
),
Actor_Summary AS (
    SELECT 
        rat.actor_name,
        fm.title,
        fm.production_year,
        fm.company_count
    FROM 
        Recursive_Actor_Titles rat
    INNER JOIN 
        Filtered_Movies fm ON rat.movie_title = fm.title
    WHERE 
        rat.title_rank <= 5
    ORDER BY 
        rat.actor_name, fm.production_year DESC
)

SELECT 
    asu.actor_name,
    COUNT(DISTINCT asu.title) AS total_movies,
    AVG(COALESCE(asu.company_count, 0)) AS avg_companies,
    LISTAGG(DISTINCT asu.title, ', ') WITHIN GROUP (ORDER BY asu.title) AS movie_list
FROM 
    Actor_Summary asu
GROUP BY 
    asu.actor_name
HAVING 
    COUNT(asu.title) > 2
ORDER BY 
    total_movies DESC, avg_companies DESC;
