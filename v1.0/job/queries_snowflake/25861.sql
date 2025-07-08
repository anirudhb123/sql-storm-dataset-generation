WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t 
    WHERE 
        t.title ILIKE '%adventure%'
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ti.title,
        ti.production_year,
        a.name AS actor_name
    FROM 
        movie_companies mt
    JOIN 
        company_name c ON c.id = mt.company_id
    JOIN 
        company_type ct ON ct.id = mt.company_type_id
    JOIN 
        title ti ON ti.id = mt.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = ti.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id 
    WHERE 
        ti.production_year >= 2000
        AND ci.nr_order < 5
        AND c.country_code = 'USA'
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_name,
        md.company_type,
        COUNT(*) AS actor_count
    FROM 
        MovieDetails md
    JOIN 
        RankedTitles rt ON md.title = rt.title
    GROUP BY 
        md.title, md.production_year, md.company_name, md.company_type
)
SELECT 
    title,
    production_year,
    company_name,
    company_type,
    actor_count
FROM 
    FinalResults
WHERE 
    actor_count > 2
ORDER BY 
    production_year DESC, title ASC;
