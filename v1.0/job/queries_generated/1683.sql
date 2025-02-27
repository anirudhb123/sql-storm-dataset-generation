WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN 
        RankedMovies rm ON cc.movie_id = rm.movie_id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT m.movie_id) > 5
),
ActorNames AS (
    SELECT 
        a.person_id,
        a.name
    FROM 
        aka_name a
    JOIN 
        PopularActors pa ON a.person_id = pa.person_id
)

SELECT 
    rm.production_year,
    rm.title,
    an.name AS actor_name,
    COALESCE(k.keyword, 'No keyword') AS keyword,
    COUNT(mc.company_id) AS company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id AND cc.subject_id = ci.person_id
JOIN 
    ActorNames an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank_in_year <= 10 AND
    (rm.production_year > 2000 OR k.keyword IS NOT NULL)
GROUP BY 
    rm.production_year, rm.title, an.name, k.keyword
ORDER BY 
    rm.production_year DESC, COUNT(mc.company_id) DESC;
