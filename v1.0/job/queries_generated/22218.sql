WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 5
),
ActorDetails AS (
    SELECT 
        ai.person_id,
        k.keyword,
        COUNT(DISTINCT ai.movie_id) AS movie_count,
        SUM(CASE WHEN ai.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info ai
    JOIN 
        movie_keyword mk ON ai.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ai.person_id, k.keyword
),
AggregatedRoles AS (
    SELECT 
        ad.person_id,
        STRING_AGG(DISTINCT ad.keyword, ', ') AS keywords,
        SUM(ad.movie_count) AS total_movies,
        SUM(ad.lead_roles) AS total_leads
    FROM 
        ActorDetails ad
    GROUP BY 
        ad.person_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    ar.keywords,
    ar.total_movies,
    ar.total_leads,
    COALESCE(NULLIF(ar.total_leads, 0), 1) AS lead_adjusted
FROM 
    FilteredMovies fm
LEFT JOIN 
    AggregatedRoles ar ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = fm.movie_id 
        AND ci.person_id IN (SELECT person_id FROM ActorDetails)
    )
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC
LIMIT 100;

