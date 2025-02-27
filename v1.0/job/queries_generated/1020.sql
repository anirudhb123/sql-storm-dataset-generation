WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT cc.person_id) AS total_actors,
        AVG(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        t.id AS movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        t.id, cn.name, ct.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_actors,
    md.actors_with_notes,
    md.actor_names,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    cd.total_companies
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.production_year = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.total_actors DESC;
