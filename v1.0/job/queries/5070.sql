WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        STRING_AGG(DISTINCT c2.kind, ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c2 ON mc.company_type_id = c2.id
    GROUP BY 
        t.id, t.title, t.production_year
), ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        p.info AS biography
    FROM 
        aka_name a
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.total_keywords,
    ms.company_types,
    ai.actor_id,
    ai.name AS actor_name,
    ai.biography
FROM 
    MovieStats ms
JOIN 
    cast_info ci ON ms.movie_id = ci.movie_id
JOIN 
    ActorInfo ai ON ci.person_id = ai.actor_id
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC, 
    ai.name;
