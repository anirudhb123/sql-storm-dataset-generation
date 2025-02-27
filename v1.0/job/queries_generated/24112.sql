WITH Recursive_Aka_Names AS (
    SELECT id, person_id, name, imdb_index
    FROM aka_name
    WHERE name IS NOT NULL
    UNION ALL
    SELECT a.id, a.person_id, CONCAT(a.name, ' (', IFNULL(a.imdb_index, 'UNKNOWN'), ')'), a.imdb_index
    FROM aka_name a
    JOIN Recursive_Aka_Names r ON a.person_id = r.person_id
    WHERE a.id <> r.id
),
Movie_Info_CTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT c.id) AS cast_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN complete_cast c ON c.movie_id = m.id
    GROUP BY m.id
),
Role_Stats AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT ci.movie_id) AS roles_played,
        AVG(CASE WHEN ci.note LIKE '%lead%' THEN 1.0 ELSE 0 END) AS lead_role_ratio
    FROM cast_info ci
    JOIN person_info pi ON ci.person_id = pi.person_id
    WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth')
    GROUP BY p.person_id
),
Filtered_Movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM Movie_Info_CTE m
    WHERE m.keywords IS NOT NULL
      AND m.company_count >= 2
      AND m.cast_count > 5
),
Final_Results AS (
    SELECT 
        a.name AS actor_name,
        f.title AS movie_title,
        f.production_year,
        r.roles_played,
        r.lead_role_ratio,
        COALESCE(s.season_nr, 1) AS season_number,
        COALESCE(e.episode_number, 0) AS episode_number
    FROM Recursive_Aka_Names a
    JOIN Filtered_Movies f ON f.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = a.person_id)
    LEFT JOIN complete_cast e ON e.movie_id = f.movie_id
    LEFT JOIN (SELECT DISTINCT movie_id, season_nr FROM aka_title WHERE episode_nr IS NOT NULL) s ON s.movie_id = f.movie_id
    LEFT JOIN Role_Stats r ON r.person_id = a.person_id
    WHERE a.name NOT LIKE '%unknown%' 
      AND f.year_rank <= 10
      AND r.lead_role_ratio IS NOT NULL
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    roles_played,
    lead_role_ratio,
    season_number,
    episode_number 
FROM Final_Results
WHERE roles_played > 1
ORDER BY production_year DESC, actor_name;
