WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    (SELECT AVG(actor_count) FROM RankedMovies) AS avg_actor_count,
    CASE 
        WHEN rm.actor_count > (SELECT AVG(actor_count) FROM RankedMovies) THEN 'Above Average'
        WHEN rm.actor_count < (SELECT AVG(actor_count) FROM RankedMovies) THEN 'Below Average'
        ELSE 'Average'
    END AS performance_category
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;

SELECT 
    DISTINCT co.name AS company_name,
    t.title AS movie_title,
    m.production_year
FROM 
    movie_companies mc
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    aka_title t ON mc.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
    AND m.info IS NOT NULL
    AND m.note IS NULL;

SELECT 
    COUNT(*) AS total_actors,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS actors_without_notes
FROM 
    cast_info ci
WHERE 
    EXISTS (
        SELECT 1 
        FROM aka_title at 
        WHERE at.id = ci.movie_id 
        AND at.production_year >= 2000
    )
    AND ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%');

SELECT 
    t.title,
    k.keyword,
    COALESCE(mk.id, 0) AS keyword_association,
    RANK() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
FROM 
    aka_title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    OR k.keyword LIKE '%action%'
EXCEPT
SELECT 
    t.title,
    k.keyword,
    COALESCE(mk.id, 0) AS keyword_association
FROM 
    aka_title t
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    k.keyword IS NULL
ORDER BY 
    t.title;
