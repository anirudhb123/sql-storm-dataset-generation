
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rt.title,
    rt.production_year,
    ta.name AS top_actor,
    mc.companies,
    m.keyword
FROM 
    RankedTitles rt
LEFT JOIN 
    MoviesWithKeywords m ON rt.title_id = m.movie_id
INNER JOIN 
    TopActors ta ON ta.person_id IN (
        SELECT person_id 
        FROM cast_info 
        WHERE movie_id = rt.title_id
    )
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rt.title_id
WHERE 
    rt.rank_per_year <= 3
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
