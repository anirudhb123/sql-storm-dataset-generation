
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        a.name LIKE '%Smith%'
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        rt.title,
        rt.production_year,
        cc.company_count,
        RANK() OVER (PARTITION BY a.actor_id ORDER BY rt.production_year DESC) AS actor_movie_rank
    FROM 
        ActorInfo a
    JOIN 
        RankedTitles rt ON a.movie_title = rt.title AND a.production_year = rt.production_year
    LEFT JOIN 
        CompanyCounts cc ON rt.title_id = cc.movie_id
)
SELECT 
    actor_id,
    actor_name,
    title,
    production_year,
    COALESCE(company_count, 0) AS company_count,
    actor_movie_rank
FROM 
    FinalResults
WHERE 
    actor_movie_rank <= 5
ORDER BY 
    production_year DESC, company_count DESC;
