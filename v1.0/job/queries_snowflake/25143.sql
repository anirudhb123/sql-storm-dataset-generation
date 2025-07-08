
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.name) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorsInMovies AS (
    SELECT 
        a.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS number_of_actors
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        a.name, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) >= 3
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
    HAVING 
        COUNT(mk.keyword_id) > 0
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ai.actor_name,
    mk.keywords,
    mk.keyword_count
FROM 
    RankedMovies rm
JOIN 
    ActorsInMovies ai ON rm.title = ai.movie_title AND rm.production_year = ai.production_year
JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, mk.keyword_count DESC, ai.number_of_actors DESC
LIMIT 10;
