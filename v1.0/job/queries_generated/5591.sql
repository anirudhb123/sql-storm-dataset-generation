WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title AS title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        kt.kind LIKE 'movie%'
),
MovieDetails AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year, 
        mci.company_id, 
        cn.name AS company_name
    FROM 
        RankedTitles rt
    JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id 
    JOIN 
        movie_companies mci ON cc.movie_id = mci.movie_id
    JOIN 
        company_name cn ON mci.company_id = cn.id
    WHERE 
        rt.rank <= 10
),
ActorInfo AS (
    SELECT 
        ai.id AS actor_id, 
        ak.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    GROUP BY 
        ai.id, ak.name
)
SELECT 
    md.title, 
    md.production_year, 
    md.company_name, 
    ai.actor_name, 
    ai.movie_count
FROM 
    MovieDetails md
JOIN 
    ActorInfo ai ON md.title_id IN (
        SELECT 
            movie_id 
        FROM 
            cast_info 
        WHERE 
            person_id IN (SELECT person_id FROM aka_name WHERE name = ai.actor_name)
    )
ORDER BY 
    md.production_year DESC, 
    ai.movie_count DESC
LIMIT 100;
