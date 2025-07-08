WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        complete_cast c ON ci.movie_id = c.movie_id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cd.company_name, 'Unknown') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CAST(COALESCE(cd.company_count, 0) AS VARCHAR) || ' companies involved' AS company_info
FROM 
    RankedMovies m
LEFT JOIN 
    ActorCount ac ON m.movie_id = ac.movie_id
LEFT JOIN 
    CompanyDetails cd ON m.movie_id = cd.movie_id
WHERE 
    m.rank_by_title <= 10
ORDER BY 
    m.production_year DESC, m.title;
