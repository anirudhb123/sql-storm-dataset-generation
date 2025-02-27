WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE NULL END) AS avg_order,
        MAX(CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'N/A' END) AS notes
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),

FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actors,
        cd.companies,
        cd.company_types,
        md.avg_order,
        md.notes
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
    WHERE 
        md.cast_count > 0
)

SELECT 
    FO.*,
    CASE 
        WHEN FO.cast_count IS NULL THEN 'No Cast Information'
        ELSE 'Cast Information Present'
    END AS cast_info_status
FROM 
    FinalOutput FO
ORDER BY 
    FO.production_year DESC, FO.title ASC;
