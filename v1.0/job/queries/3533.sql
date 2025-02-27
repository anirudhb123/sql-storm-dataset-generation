WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyContribution AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.total_cast,
        coalesce(cc.company_names, 'No Companies') AS company_names,
        coalesce(cc.total_companies, 0) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank_by_cast
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyContribution cc ON md.movie_id = cc.movie_id
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.total_cast,
    fb.company_names,
    fb.total_companies,
    fb.rank_by_cast
FROM 
    FinalBenchmark fb
WHERE 
    fb.rank_by_cast <= 5
ORDER BY 
    fb.production_year DESC, fb.total_cast DESC;
