WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
DirectorActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        rc.movie_id,
        rc.title 
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rc ON ci.movie_id = rc.movie_id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'actor') 
        AND rc.rank <= 10
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT mi.info, ', ') AS additional_info
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        ra.movie_id,
        ra.title,
        ra.production_year,
        da.actor_name,
        da.actor_id,
        cm.companies,
        cm.additional_info
    FROM 
        RankedMovies ra
    LEFT JOIN 
        DirectorActors da ON ra.movie_id = da.movie_id
    LEFT JOIN 
        CompanyMovieInfo cm ON ra.movie_id = cm.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    companies,
    additional_info
FROM 
    FinalResults
WHERE 
    actor_id IS NOT NULL
ORDER BY 
    production_year DESC, total_cast DESC NULLS LAST;
