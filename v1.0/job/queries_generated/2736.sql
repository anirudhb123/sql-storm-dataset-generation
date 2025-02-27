WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
), ActorCounts AS (
    SELECT 
        ca.movie_id,
        COUNT(ca.person_id) AS actor_count
    FROM 
        cast_info ca
    GROUP BY 
        ca.movie_id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cm.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cm ON mc.company_id = cm.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), TopActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
), MovieDetails AS (
    SELECT 
        t.title_id,
        t.title,
        t.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mc.company_name, 'Unknown') AS company_name
    FROM 
        RankedTitles t
    LEFT JOIN 
        ActorCounts ac ON t.title_id = ac.movie_id
    LEFT JOIN 
        MovieCompanies mc ON t.title_id = mc.movie_id AND mc.company_rank = 1
)

SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    ta.actor_name,
    ta.movies_count
FROM 
    MovieDetails md
LEFT JOIN 
    TopActors ta ON md.actor_count > 3
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC, 
    md.title;
