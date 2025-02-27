WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
Combined AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.avg_order,
        cd.companies,
        CASE 
            WHEN md.total_cast > 5 THEN 'Large Cast' 
            ELSE 'Small Cast' 
        END AS cast_size,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank_within_year
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.title_id = cd.movie_id
)
SELECT 
    title,
    production_year,
    total_cast,
    avg_order,
    companies,
    cast_size
FROM 
    Combined
WHERE 
    rank_within_year <= 10 AND (companies IS NOT NULL OR avg_order > 0)
ORDER BY 
    production_year DESC, total_cast DESC;
