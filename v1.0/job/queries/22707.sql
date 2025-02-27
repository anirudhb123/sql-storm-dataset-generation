WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COALESCE(at.season_nr, 0), at.episode_nr) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COALESCE(ai.info, 'No Info') AS additional_info,
        ar.movie_count,
        ar.roles
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info ai ON ak.person_id = ai.person_id AND ai.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
    JOIN 
        ActorRoles ar ON ak.person_id = ar.person_id
)
SELECT 
    am.title,
    am.production_year,
    ad.actor_name,
    ad.additional_info,
    ad.movie_count,
    ad.roles
FROM 
    RankedMovies am
LEFT JOIN 
    complete_cast cc ON am.title_id = cc.movie_id
LEFT JOIN 
    ActorDetails ad ON cc.subject_id = ad.person_id
WHERE 
    am.title_rank <= 5
    AND (ad.roles IS NULL OR ad.roles LIKE '%Lead%')
ORDER BY 
    am.production_year DESC,
    ad.movie_count DESC,
    ad.actor_name ASC;