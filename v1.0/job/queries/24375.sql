WITH RecursiveActorTitles AS (
    SELECT 
        ka.person_id,
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY kt.production_year DESC) AS title_rank
    FROM 
        aka_name AS ka
    JOIN 
        cast_info AS ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title AS kt ON ci.movie_id = kt.movie_id 
    WHERE 
        kt.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        rat.person_id,
        rat.actor_name,
        COUNT(rat.movie_title) AS movie_count,
        STRING_AGG(DISTINCT rat.movie_title || ' (' || rat.production_year || ')', ', ') AS movie_titles
    FROM 
        RecursiveActorTitles AS rat
    GROUP BY 
        rat.person_id,
        rat.actor_name
),
NullInfoType AS (
    SELECT 
        p.id AS person_id,
        p.name,
        pi.info AS person_info
    FROM 
        name AS p
    LEFT JOIN 
        person_info AS pi ON p.id = pi.person_id 
    WHERE 
        pi.info IS NULL
)
SELECT 
    ami.actor_name,
    ami.movie_count,
    ami.movie_titles,
    ni.person_info
FROM 
    ActorMovieInfo AS ami
LEFT JOIN 
    NullInfoType AS ni ON ami.person_id = ni.person_id
WHERE 
    ami.movie_count > 5
ORDER BY 
    ami.movie_count DESC,
    ami.actor_name ASC
LIMIT 10;