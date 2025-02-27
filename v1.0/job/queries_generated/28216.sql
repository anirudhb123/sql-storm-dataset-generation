WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        m.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count
    FROM 
        title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, a.name, m.production_year
),
RankedMovies AS (
    SELECT 
        movie_title,
        actor_name,
        production_year,
        keyword_count,
        has_notes,
        company_names,
        cast_count,
        RANK() OVER (ORDER BY keyword_count DESC, production_year DESC) AS movie_rank
    FROM 
        MovieStats
)
SELECT 
    movie_title,
    actor_name,
    production_year,
    keyword_count,
    has_notes,
    company_names,
    cast_count,
    movie_rank
FROM 
    RankedMovies
WHERE 
    movie_rank <= 10
ORDER BY 
    movie_rank;
