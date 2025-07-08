
WITH RankedMovies AS (
    SELECT 
        tit.id AS movie_id,
        tit.title,
        tit.production_year,
        DENSE_RANK() OVER (PARTITION BY tit.production_year ORDER BY tit.title) AS title_rank
    FROM 
        aka_title AS tit
    WHERE 
        tit.production_year BETWEEN 2000 AND 2023
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        COUNT(ci.person_role_id) AS role_count
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mt
    JOIN 
        keyword AS k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
FinalOutput AS (
    SELECT 
        movie.title,
        movie.production_year,
        actors.actor_name,
        actors.role,
        companies.company_name,
        companies.company_type,
        mwk.keywords,
        COALESCE(actors.role_count, 0) AS role_count,
        RANK() OVER (ORDER BY COALESCE(actors.role_count, 0) DESC) AS rank_by_role
    FROM 
        RankedMovies AS movie
    LEFT JOIN 
        ActorRoles AS actors ON movie.movie_id = actors.movie_id
    LEFT JOIN 
        CompanyRoles AS companies ON movie.movie_id = companies.movie_id
    LEFT JOIN 
        MoviesWithKeywords AS mwk ON movie.movie_id = mwk.movie_id
    WHERE 
        (movie.production_year IS NOT NULL OR companies.company_type IS NULL) AND 
        (LOWER(movie.title) LIKE '%adventure%' OR LOWER(actors.actor_name) LIKE 'john%')
)
SELECT 
    title,
    production_year,
    actor_name,
    role,
    company_name,
    company_type,
    keywords,
    role_count,
    rank_by_role
FROM 
    FinalOutput
WHERE 
    (role_count > 1 OR keywords IS NOT NULL)
ORDER BY 
    rank_by_role, production_year DESC, title;
