
WITH Actor_Info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        p.gender AS actor_gender,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    GROUP BY 
        a.id, a.name, p.gender
),
Movie_Stats AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
Company_Info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    ai.actor_name,
    ai.actor_gender,
    ms.movie_title,
    ms.production_year,
    ms.cast_count,
    ci.company_name,
    ci.company_type
FROM 
    Actor_Info ai
JOIN 
    cast_info c ON ai.actor_id = c.person_id
JOIN 
    Movie_Stats ms ON c.movie_id = ms.movie_id
JOIN 
    Company_Info ci ON ci.movie_id = ms.movie_id
WHERE 
    ai.movie_count > 5 
ORDER BY 
    ms.production_year DESC, 
    ai.actor_name ASC;
