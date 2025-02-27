WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT k.id FROM kind_type k WHERE k.kind LIKE 'feature%')
),
ActorInfo AS (
    SELECT 
        a.name, 
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    ai.name AS actor_name,
    ai.movie_count,
    ai.avg_order,
    cd.company_name,
    cd.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT id FROM aka_name WHERE name = ai.name))
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_per_year <= 3
ORDER BY 
    rm.production_year DESC, 
    ai.movie_count DESC, 
    rm.title
LIMIT 100;
