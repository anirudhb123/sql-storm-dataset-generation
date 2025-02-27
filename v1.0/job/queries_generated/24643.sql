WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        1 AS level 
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000 
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id, 
        mt.title, 
        m.level + 1 
    FROM 
        movie_link mc 
    JOIN 
        movie_chain m ON mc.movie_id = m.movie_id 
    JOIN 
        aka_title mt ON mc.linked_movie_id = mt.id 
    WHERE 
        m.level < 5 
)

SELECT 
    a.id AS aka_id,
    a.name AS actor_name, 
    t.title, 
    t.production_year, 
    COUNT(DISTINCT cc.id) OVER (PARTITION BY a.id) AS movies_as_actor,
    ARRAY_AGG(DISTINCT CASE WHEN ak.keyword IS NOT NULL THEN ak.keyword END) FILTER (WHERE ak.keyword IS NOT NULL) AS keywords,
    string_agg(DISTINCT co.name, ', ') FILTER (WHERE co.name IS NOT NULL) AS companies,
    CASE 
        WHEN COUNT(DISTINCT cc.id) > 0 THEN 
            'Featured' 
        ELSE 
            'Non-featured' 
    END AS actor_status
FROM 
    aka_name a 
LEFT JOIN 
    cast_info cc ON a.person_id = cc.person_id 
LEFT JOIN 
    aka_title t ON cc.movie_id = t.id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
LEFT JOIN 
    keyword ak ON mk.keyword_id = ak.id 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id 
LEFT JOIN 
    company_name co ON mc.company_id = co.id 
WHERE 
    t.production_year IS NOT NULL
    AND (t.production_year < 2025 OR t.production_year IS NULL)
    AND ak.keyword NOT LIKE 'Horror' 
GROUP BY 
    a.id, t.id
HAVING 
    COUNT(DISTINCT cc.id) > 0 
ORDER BY 
    movies_as_actor DESC, actor_name;

-- Add a correlated subquery to fetch info from 'person_info' if the actor has appeared in more movies than a certain average
FROM 
    person_info pi
WHERE 
    pi.person_id = a.person_id 
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Nominations')
    AND pi.info::integer > (SELECT AVG(movie_count) 
                              FROM (SELECT COUNT(DISTINCT movie_id) AS movie_count 
                                    FROM cast_info 
                                    GROUP BY person_id) AS average_counts)
LIMIT 100;

