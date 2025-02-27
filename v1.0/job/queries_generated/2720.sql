WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS title_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
HighlightMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(CASE WHEN at.title_count > 0 THEN at.title_count ELSE NULL END), 0) AS actor_count,
        COUNT(DISTINCT cd.company_name) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorTitles at ON rm.movie_id = at.person_id  -- Mocking the join for titles acting on the movie 
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.rank_year <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    hm.title,
    hm.production_year,
    hm.actor_count,
    hm.company_count,
    CASE 
        WHEN hm.actor_count > 10 THEN 'Highly Casted'
        WHEN hm.actor_count BETWEEN 5 AND 10 THEN 'Moderately Casted'
        ELSE 'Low Casted'
    END AS casting_quality
FROM 
    HighlightMovies hm
WHERE 
    hm.company_count > 1
ORDER BY 
    hm.production_year DESC, hm.title;
