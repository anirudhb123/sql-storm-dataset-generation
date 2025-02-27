WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        p.person_id,
        a.name,
        c.movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY c.nr_order) AS actor_title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
)
SELECT 
    am.name AS actor_name,
    tt.title,
    tt.production_year,
    CASE 
        WHEN am.actor_title_rank = 1 THEN 'Lead Role'
        WHEN am.actor_title_rank BETWEEN 2 AND 5 THEN 'Supporting Role'
        ELSE 'Minor Role'
    END AS role_description,
    (SELECT COUNT(DISTINCT m.id) 
     FROM movie_keyword mk
     JOIN movie_info mi ON mk.movie_id = mi.movie_id
     WHERE mi.info LIKE '%award%'
       AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Best%')
       AND mk.movie_id = c.movie_id) AS award_count
FROM 
    ActorMovies am
JOIN 
    RankedTitles tt ON am.movie_id = tt.title_id
LEFT JOIN 
    aka_title at ON tt.title LIKE CONCAT('%', at.title, '%') AND at.production_year = tt.production_year
WHERE 
    tt.title_rank <= 5
  AND am.name IS NOT NULL
ORDER BY 
    tt.production_year DESC,
    tt.title;

-- Additional part to illustrate an obscure corner case
WITH ErrorCheck AS (
    SELECT 
        t.id AS title_id,
        COALESCE(at.title, 'Unknown Title') AS resolved_title,
        t.production_year,
        LAG(t.production_year) OVER (ORDER BY t.production_year) AS previous_year
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.title = at.title
)
SELECT 
    ec.title_id,
    ec.resolved_title,
    ec.production_year,
    CASE 
        WHEN ec.previous_year IS NOT NULL THEN
            CASE
                WHEN ec.production_year - ec.previous_year = 1 THEN 'Consecutive Year Release'
                WHEN ec.production_year - ec.previous_year > 1 THEN 'Gap in Years'
                ELSE 'Same Year'
            END
        ELSE 'No Data'
    END AS release_year_comparison
FROM 
    ErrorCheck ec
WHERE 
    ec.production_year IS NOT NULL
ORDER BY 
    ec.production_year DESC;
