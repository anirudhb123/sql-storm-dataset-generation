WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ki.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ki.keyword) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ExtendedMovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
FinalOutput AS (
    SELECT 
        em.movie_id,
        em.title,
        em.production_year,
        em.company_count,
        em.companies,
        ar.actor_name,
        ar.role_name,
        ar.cast_count,
        CASE 
            WHEN ar.cast_count = 0 THEN 'No Cast'
            ELSE 'Has Cast'
        END AS cast_status
    FROM 
        ExtendedMovieInfo em
    LEFT JOIN 
        ActorRoles ar ON em.movie_id = ar.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    company_count,
    companies,
    actor_name,
    role_name,
    cast_count,
    cast_status
FROM 
    FinalOutput
WHERE 
    (CAST(cast_count AS INT) > 0 OR companies IS NOT NULL)
ORDER BY 
    production_year DESC, 
    title ASC;
