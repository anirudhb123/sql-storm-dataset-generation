WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        an.name,
        ac.movie_count
    FROM 
        aka_name an
    JOIN 
        ActorMovieCounts ac ON an.person_id = ac.person_id
    WHERE 
        ac.movie_count > (
            SELECT 
                AVG(movie_count) 
            FROM 
                ActorMovieCounts
        )
),
CompanyMovieCounts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
)
SELECT 
    tt.title,
    tt.production_year,
    ta.name AS actor_name,
    cm.company_id,
    COALESCE(cmc.movie_count, 0) AS company_movie_count
FROM 
    RankedTitles tt
LEFT JOIN 
    cast_info ci ON ci.movie_id = tt.title_id
LEFT JOIN 
    TopActors ta ON ci.person_id = ta.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tt.title_id
LEFT JOIN 
    CompanyMovieCounts cmc ON mc.company_id = cmc.company_id
WHERE 
    tt.rn BETWEEN 1 AND 5
ORDER BY 
    tt.production_year DESC, 
    tt.title;
