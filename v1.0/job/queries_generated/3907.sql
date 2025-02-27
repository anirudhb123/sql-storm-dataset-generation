WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        a.name, 
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
),
CompanyTitleCounts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mt.id) AS title_count
    FROM 
        movie_companies mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mc.company_id
)
SELECT 
    ta.name AS actor_name,
    COALESCE(ctc.title_count, 0) AS company_title_count
FROM 
    TopActors ta
LEFT JOIN 
    CompanyTitleCounts ctc ON ctc.company_id IN (
        SELECT 
            mc.company_id 
        FROM 
            movie_companies mc
        JOIN 
            cast_info ci ON mc.movie_id = ci.movie_id
        WHERE 
            ci.person_id = ta.person_id
    )
ORDER BY 
    company_title_count DESC, actor_name;
