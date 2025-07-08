
WITH MovieRanked AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.title, m.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') AS company_names,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(ci.company_names, 'No Companies') AS company_names,
        COALESCE(ci.company_count, 0) AS company_count,
        mr.total_cast,
        mr.rank
    FROM 
        aka_title m
    LEFT JOIN 
        CompanyInfo ci ON m.id = ci.movie_id
    LEFT JOIN 
        MovieRanked mr ON m.title = mr.title
)
SELECT 
    md.title,
    md.production_year,
    md.company_names,
    md.company_count,
    md.total_cast,
    md.rank
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
    AND md.company_count > 0
ORDER BY 
    md.rank, md.production_year;
