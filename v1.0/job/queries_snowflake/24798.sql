
WITH RecursiveTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
SelectedMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(actors.movies_count, 0) AS actor_count,
        COALESCE(companies.company_count, 0) AS company_count
    FROM 
        RecursiveTitle rt
    LEFT JOIN 
        ActorRoleCounts actors ON rt.title_id = (
            SELECT movie_id 
            FROM cast_info ci 
            WHERE ci.person_id = actors.person_id 
            LIMIT 1
        )
    LEFT JOIN 
        MovieCompanyDetails companies ON rt.title_id = companies.movie_id
    WHERE 
        rt.rn <= 5 
)
SELECT 
    sm.title,
    sm.production_year,
    sm.actor_count,
    sm.company_count,
    CASE 
        WHEN sm.actor_count > 3 AND sm.company_count > 0 THEN 'Highly Collaborated'
        WHEN sm.actor_count <= 3 THEN 'Few Actors'
        ELSE 'Other'
    END AS collaboration_category
FROM 
    SelectedMovies sm
WHERE 
    sm.actor_count IS NOT NULL
ORDER BY 
    sm.production_year DESC, 
    sm.title ASC;
