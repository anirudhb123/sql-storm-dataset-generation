
WITH RECURSIVE Actor_Bio AS (
    SELECT 
        ci.person_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS movie_rank,
        COALESCE(ci.note, 'No Role Info') AS role_note,
        ci.movie_id
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
), 
Company_Movie AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ab.actor_name,
    ab.movie_title,
    ab.production_year,
    ab.movie_rank,
    cm.companies,
    cm.company_count,
    (SELECT COUNT(*)
     FROM cast_info ci_sub
     WHERE ci_sub.movie_id = ab.movie_id AND ci_sub.person_id <> ab.person_id) AS co_actors_count,
    CASE 
        WHEN ab.role_note IS NULL THEN 'Unknown Role'
        ELSE ab.role_note
    END AS role_description
FROM 
    Actor_Bio ab
LEFT JOIN 
    Company_Movie cm ON ab.movie_id = cm.movie_id
WHERE 
    ab.movie_rank <= 5
ORDER BY 
    ab.production_year DESC, ab.actor_name;
