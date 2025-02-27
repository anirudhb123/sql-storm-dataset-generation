WITH Recursive_Actor_Movie AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON c.person_id = a.person_id
    INNER JOIN 
        aka_title t ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
), 
Top_Actors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        title,
        production_year,
        movie_rank
    FROM 
        Recursive_Actor_Movie
    WHERE 
        movie_rank <= 3
),
Companies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COALESCE(MIN(ct.kind), 'Unknown') AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
),
Actor_Info AS (
    SELECT 
        ta.actor_id,
        ta.actor_name,
        ta.title,
        ta.production_year,
        c.companies,
        c.company_type,
        COALESCE(mi.info, 'No Info Available') AS additional_info
    FROM 
        Top_Actors ta
    LEFT JOIN 
        Companies c ON c.movie_id = ta.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = ta.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
)
SELECT 
    ai.actor_id,
    ai.actor_name,
    ai.title,
    ai.production_year,
    ai.companies,
    ai.company_type,
    ai.additional_info,
    CASE 
        WHEN ai.add_info IS NULL THEN 'No awards listed'
        ELSE 'Awards present'
    END AS award_status
FROM 
    Actor_Info ai
WHERE 
    ai.production_year >= 2000
AND 
    (ai.company_type IS NOT NULL OR ai.company_type <> 'Unknown')
ORDER BY 
    ai.production_year DESC, ai.actor_name;
