WITH MovieDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        t.kind_id AS kind_id,
        COUNT(cc.id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id AND ci.person_id = cc.subject_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.id, t.id
    HAVING 
        COUNT(cc.id) > 0
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

RankedMovies AS (
    SELECT 
        md.actor_id,
        md.actor_name,
        md.movie_title,
        md.kind_id,
        md.production_year,
        ROW_NUMBER() OVER (PARTITION BY md.actor_id ORDER BY md.role_count DESC) AS actor_movie_rank
    FROM 
        MovieDetails md
)

SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    cd.company_name,
    cd.company_type,
    COALESCE(cd.note_count, 0) AS company_note_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_title = cd.movie_id
WHERE 
    rm.actor_movie_rank <= 3
ORDER BY 
    rm.actor_name, rm.production_year DESC;
