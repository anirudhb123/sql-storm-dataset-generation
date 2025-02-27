WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS m
    JOIN 
        cast_info AS c ON m.movie_id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
HighActorCountMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count, 
        aliases, 
        keywords
    FROM 
        RankedMovies
    WHERE 
        actor_count >= 5
)
SELECT 
    ham.movie_id,
    ham.title,
    ham.production_year,
    ham.actor_count,
    ham.aliases,
    ham.keywords,
    COMP.name AS production_company,
    CT.kind AS company_type
FROM 
    HighActorCountMovies AS ham
JOIN 
    movie_companies AS mc ON ham.movie_id = mc.movie_id
JOIN 
    company_name AS COMP ON mc.company_id = COMP.id
JOIN 
    company_type AS CT ON mc.company_type_id = CT.id
ORDER BY 
    ham.actor_count DESC, 
    ham.production_year ASC;