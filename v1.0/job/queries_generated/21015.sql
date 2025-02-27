WITH RecursiveActorInfo AS (
    SELECT 
        c.id AS cast_info_id,
        c.person_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5sum,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL AND 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
)

SELECT 
    actor_info.actor_name,
    STRING_AGG(DISTINCT movie_info.info, ', ') AS movie_infos,
    COUNT(DISTINCT movie_info.movie_id) AS total_movies,
    MAX(actor_info.recent_movie_rank) AS max_rank,
    (SELECT COUNT(*)
     FROM cast_info ci 
     JOIN aka_title at ON ci.movie_id = at.id
     WHERE ci.person_id = actor_info.person_id AND 
           at.production_year < (SELECT MAX(a.production_year) FROM RecursiveActorInfo a WHERE a.person_id = actor_info.person_id)
    ) AS earlier_movies_count,
    CASE 
        WHEN MAX(actor_info.recent_movie_rank) = 1 THEN 'Leading Actor'
        WHEN count(DISTINCT movie_info.movie_id) > 5 THEN 'Frequent Collaborator'
        ELSE 'Occasional Contributor'
    END AS actor_category
FROM 
    RecursiveActorInfo actor_info
LEFT JOIN 
    movie_info movie_info ON actor_info.movie_title = movie_info.info 
WHERE 
    movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
GROUP BY 
    actor_info.actor_name
HAVING 
    COUNT(DISTINCT movie_info.movie_id) > 2
ORDER BY 
    total_movies DESC
LIMIT 10
OFFSET 0;
