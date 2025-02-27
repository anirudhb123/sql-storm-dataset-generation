WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND ak.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, ak.name, ct.kind
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        company_type,
        keywords,
        actor_count,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS actor_ranking
    FROM 
        MovieDetails
)
SELECT 
    production_year,
    movie_title,
    actor_name,
    company_type,
    keywords
FROM 
    RankedMovies
WHERE 
    actor_ranking <= 5
ORDER BY 
    production_year, actor_ranking;
