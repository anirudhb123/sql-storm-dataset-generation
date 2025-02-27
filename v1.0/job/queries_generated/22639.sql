WITH RecursiveActorMovies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.nr_order IS NOT NULL -- Exclude un-ordered roles
), 
ActorAwards AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT a.id) AS award_count
    FROM 
        person_info p
    LEFT JOIN 
        (SELECT DISTINCT title_id, person_id FROM movie_info m WHERE m.note ILIKE '%award%') a ON p.person_id = a.person_id
    GROUP BY 
        p.person_id
), 
AllActors AS (
    SELECT 
        a.person_id,
        a.name,
        COALESCE(aw.award_count, 0) AS award_count,
        am.title,
        am.production_year
    FROM 
        aka_name a
    LEFT JOIN 
        ActorAwards aw ON a.person_id = aw.person_id
    LEFT JOIN 
        RecursiveActorMovies am ON a.person_id = am.person_id
    WHERE 
        am.rn <= 3 OR am.rn IS NULL -- Get top 3 movies or NULL
)
SELECT 
    na.name,
    COUNT(DISTINCT na.person_id) AS total_actors,
    STRING_AGG(DISTINCT na.title, ', ') AS titles,
    AVG(CASE WHEN na.production_year IS NOT NULL THEN na.production_year ELSE 0 END) AS avg_production_year,
    SUM(CASE WHEN na.award_count > 0 THEN 1 ELSE 0 END) AS actors_with_awards,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword k 
     JOIN aka_title t ON k.movie_id = t.id 
     WHERE t.title ILIKE '%' || COALESCE(NULLIF(na.title, ''), 'No Title') || '%') AS count_keywords
FROM 
    AllActors na
GROUP BY 
    na.name
HAVING 
    SUM(CASE WHEN na.production_year < 2000 THEN 1 ELSE 0 END) > 1
ORDER BY 
    total_actors DESC NULLS LAST;
