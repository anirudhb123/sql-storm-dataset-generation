WITH MovieTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind_type,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        title t
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),

CharacterRoles AS (
    SELECT 
        ci.movie_id, 
        ci.person_id,
        pt.role AS role_type,
        COUNT(*) AS appearances
    FROM 
        cast_info ci
    JOIN 
        role_type pt ON ci.person_role_id = pt.id
    GROUP BY 
        ci.movie_id, ci.person_id, pt.role
),

ActorName AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        ak.imdb_index,
        ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY ak.name) AS row_num
    FROM 
        aka_name ak
),

TopActors AS (
    SELECT 
        cn.movie_id,
        STRING_AGG(DISTINCT an.actor_name, ', ') AS top_actors
    FROM 
        CharacterRoles cn
    JOIN 
        ActorName an ON cn.person_id = an.person_id
    WHERE 
        cn.appearances > 1
    GROUP BY 
        cn.movie_id
)

SELECT 
    mti.title,
    mti.production_year,
    mti.kind_type,
    mti.production_company_count,
    COALESCE(ta.top_actors, 'Unknown') AS top_actors
FROM 
    MovieTitleInfo mti
LEFT JOIN 
    TopActors ta ON mti.title_id = ta.movie_id
ORDER BY 
    mti.production_year DESC,
    mti.title;