WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCast AS (
    SELECT 
        m.title, 
        m.production_year,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY m.title ORDER BY c.nr_order) AS actor_order
    FROM 
        RankedMovies m
    JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)
    JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        m.year_rank = 1 
    ORDER BY 
        m.title
),
CompanyInfo AS (
    SELECT 
        m.title, 
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    GROUP BY 
        m.title
),
FinalResults AS (
    SELECT 
        mc.title,
        mc.production_year,
        mc.actor_name,
        mc.actor_order,
        co.company_count,
        co.company_names
    FROM 
        MovieCast mc
    LEFT JOIN 
        CompanyInfo co ON co.title = mc.title
)
SELECT 
    title, 
    production_year, 
    actor_name, 
    actor_order, 
    COALESCE(company_count, 0) AS company_count,
    COALESCE(company_names, 'No companies linked') AS company_names
FROM 
    FinalResults
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, 
    actor_order;
