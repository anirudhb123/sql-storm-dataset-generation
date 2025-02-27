WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),

TopMovies AS (
    SELECT 
        title,
        production_year,
        kind_id
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),

ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        mt.title AS movie_title,
        ct.kind AS role_type,
        COALESCE(COUNT(DISTINCT ci.nr_order), 0) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        aka_title mt ON ci.movie_id = mt.id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        mt.kind_id IN (SELECT DISTINCT kind_id FROM TopMovies)
    GROUP BY 
        a.name, mt.title, ct.kind
),

FinalResults AS (
    SELECT 
        ta.title,
        ta.production_year,
        ta.kind_id,
        ar.actor_name,
        ar.role_type,
        ar.role_count,
        CASE 
            WHEN ar.role_count > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS role_status
    FROM 
        TopMovies ta
    LEFT JOIN 
        ActorRoles ar ON ta.title = ar.movie_title
)

SELECT 
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.role_type,
    fr.role_count,
    fr.role_status
FROM 
    FinalResults fr
WHERE 
    fr.role_status = 'Active'
ORDER BY 
    fr.production_year DESC, 
    fr.title
LIMIT 10;
