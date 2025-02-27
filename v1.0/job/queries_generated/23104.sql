WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name, ak.id
),
CompaniesWithInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.unique_roles,
        ci.total_movies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        CompaniesWithInfo ci ON rm.movie_id = ci.movie_id
    WHERE 
        (rm.rank_by_cast_size <= 5 OR rm.production_year % 2 = 0) 
        AND (cd.unique_roles IS NOT NULL OR ci.total_movies > 2)
)
SELECT 
    fm.title,
    CASE 
        WHEN fm.production_year IS NULL THEN 'No Year'
        ELSE CAST(fm.production_year AS TEXT) 
    END AS production_year,
    COUNT(DISTINCT fm.actor_name) AS total_actors,
    STRING_AGG(DISTINCT fm.actor_name, ', ') AS actor_list
FROM 
    FilteredMovies fm
GROUP BY 
    fm.title, fm.production_year
HAVING 
    COUNT(DISTINCT fm.actor_name) > 1
ORDER BY 
    total_actors DESC, fm.production_year DESC;
