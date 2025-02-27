WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        SUM(COALESCE(ci.nr_order, 0)) AS total_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 0 AND 
        COUNT(DISTINCT CASE 
            WHEN a.name IS NULL THEN 1 
        END) = 0
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name ORDER BY c.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT mc.company_id) <= 5
),
ActorAwards AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT pi.info) AS award_count
    FROM 
        cast_info ci
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY 
        ci.movie_id
),
FinalSelection AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        cd.company_names,
        ca.award_count,
        md.num_actors,
        md.total_order,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.num_actors DESC, md.total_order DESC) AS rank
    FROM 
        MovieDetails md
    JOIN 
        CompanyDetails cd ON md.title_id = cd.movie_id
    LEFT JOIN 
        ActorAwards ca ON md.title_id = ca.movie_id
)
SELECT 
    title_id,
    title,
    production_year,
    company_names,
    COALESCE(award_count, 0) AS award_count,
    num_actors,
    total_order,
    rank
FROM 
    FinalSelection
WHERE 
    production_year >= 2000 
    AND num_actors > 1 
    AND (award_count IS NULL OR award_count > 1)
ORDER BY 
    production_year DESC, rank ASC
LIMIT 10;
