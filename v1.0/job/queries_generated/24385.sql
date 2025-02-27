WITH RankedMovies AS (
    SELECT 
        m.title, 
        m.production_year, 
        c.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY c.kind_id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    JOIN 
        kind_type c ON m.kind_id = c.id
    WHERE 
        m.production_year IS NOT NULL
),
CastStats AS (
    SELECT 
        p.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        p.name
),
Companies AS (
    SELECT 
        co.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS num_movies_produced
    FROM 
        company_name co
    JOIN 
        movie_companies mc ON co.id = mc.company_id
    GROUP BY 
        co.name
),
FilteredCompanies AS (
    SELECT 
        company_name,
        num_movies_produced,
        DENSE_RANK() OVER (ORDER BY num_movies_produced DESC) AS rank
    FROM 
        Companies
    WHERE 
        num_movies_produced > 5
)
SELECT 
    m.title,
    m.production_year,
    c.name AS actor_name,
    cs.movie_count AS actor_movie_count,
    COALESCE(fc.company_name, 'Unknown Company') AS company,
    fc.num_movies_produced,
    RANK() OVER (PARTITION BY m.kind_id ORDER BY m.production_year) AS movie_rank
FROM 
    RankedMovies m
LEFT JOIN 
    CastStats cs ON m.title = cs.name
LEFT JOIN 
    FilteredCompanies fc ON fc.rank = 1
WHERE 
    m.rn <= 5
    AND (m.production_year IS NOT NULL OR fc.num_movies_produced > 5)
ORDER BY 
    m.production_year DESC, 
    movie_rank ASC;

-- Handling NULL logic and bizarre semantics with outer joins and complex predicates
SELECT 
    CASE 
        WHEN cs.movie_count IS NULL THEN 'No movies found'
        WHEN cs.avg_production_year IS NULL THEN 'No average year available'
        ELSE p.name || ' has appeared in ' || cs.movie_count || ' movies with an average production year of ' || COALESCE(cs.avg_production_year::text, 'N/A')
    END AS actor_summary
FROM 
    aka_name p
LEFT JOIN 
    CastStats cs ON p.name = cs.name
WHERE 
    (cs.movie_count IS NULL OR cs.avg_production_year IS NULL OR cs.avg_production_year < 2000)
ORDER BY 
    p.name;
