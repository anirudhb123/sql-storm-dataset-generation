WITH RecursiveActorTitles AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY at.production_year DESC) AS rn
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON ak.person_id = a.person_id
    JOIN 
        aka_title at ON at.id = a.movie_id
    WHERE 
        a.nr_order IS NOT NULL
),
ActorAwards AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT mw.note) AS award_count
    FROM 
        movie_info mw
    JOIN 
        complete_cast cc ON cc.movie_id = mw.movie_id
    JOIN 
        cast_info a ON a.movie_id = cc.movie_id AND a.person_id = cc.subject_id
    WHERE 
        mw.info_type_id = (SELECT id FROM info_type WHERE info = 'academy award')
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        rat.actor_name,
        rat.movie_title,
        rat.production_year,
        COALESCE(aw.award_count, 0) AS award_count
    FROM 
        RecursiveActorTitles rat
    LEFT JOIN 
        ActorAwards aw ON rat.person_id = aw.person_id
    WHERE 
        rat.rn = 1
),
QualifiedActors AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        award_count
    FROM 
        TopActors
    WHERE 
        award_count >= 3
    OR 
        (production_year < 2000 AND award_count IS NULL)
)
SELECT 
    qa.actor_name,
    qa.movie_title,
    qa.production_year,
    qa.award_count,
    CASE 
        WHEN qa.award_count IS NOT NULL THEN 'Awarded'
        ELSE 'No Award'
    END AS award_status,
    EXTRACT(YEAR FROM CURRENT_DATE) - qa.production_year AS years_since_release
FROM 
    QualifiedActors qa
ORDER BY 
    qa.production_year DESC,
    qa.award_count DESC;

-- Explanation of the query:
-- - RecursiveActorTitles CTE retrieves actors, their names, and titles in descending order by year, 
-- - ActorAwards CTE counts awards for each actor based on movie info entries.
-- - TopActors CTE merges the prior two CTEs to filter only the most recent movies (rn=1).
-- - QualifiedActors CTE filters actors with at least 3 awards or movies before 2000 without awards.
-- - Final SELECT statement returns relevant details about qualified actors, including a derived column 
--   for award status and years since movie release.
