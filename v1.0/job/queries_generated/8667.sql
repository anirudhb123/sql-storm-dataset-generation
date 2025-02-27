WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.note AS company_note,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mt
    JOIN 
        company_name cn ON mt.company_id = cn.id
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
),
ActorInfo AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        p.info AS actor_info
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info p ON ak.person_id = p.person_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        ai.actor_name,
        ai.actor_info,
        RANK() OVER (PARTITION BY cc.movie_id ORDER BY cc.nr_order) AS actor_rank
    FROM 
        cast_info cc
    JOIN 
        ActorInfo ai ON cc.person_id = ai.person_id
)
SELECT 
    rt.title,
    rt.production_year,
    mc.company_name,
    mc.company_note,
    ac.actor_name,
    ac.actor_info,
    ac.actor_rank
FROM 
    RankedTitles rt
JOIN 
    complete_cast ac ON rt.title_id = ac.movie_id
JOIN 
    MovieDetails mc ON rt.title_id = mc.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title ASC, ac.actor_rank;
