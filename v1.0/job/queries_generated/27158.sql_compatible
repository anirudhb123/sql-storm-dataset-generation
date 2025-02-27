
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
HighActorMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        keywords,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        actor_count > 10  
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    ham.title,
    ham.production_year,
    ham.aka_names,
    ham.keywords,
    mc.company_names
FROM 
    HighActorMovies AS ham
LEFT JOIN 
    MovieCompanies AS mc ON ham.movie_id = mc.movie_id
ORDER BY 
    ham.production_year DESC;
