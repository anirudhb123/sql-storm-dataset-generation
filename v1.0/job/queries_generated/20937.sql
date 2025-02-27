WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind NOT LIKE '%Short%')
    GROUP BY 
        t.id
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mt
    JOIN 
        company_name cn ON mt.company_id = cn.id
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    COALESCE(cir.actor_count, 0) AS actor_count,
    COALESCE(mwc.company_names, 'N/A') AS company_names,
    mwc.company_types
FROM 
    TopRankedMovies tr
LEFT JOIN 
    CastInfoWithRoles cir ON tr.movie_id = cir.movie_id
LEFT JOIN 
    MoviesWithCompanies mwc ON tr.movie_id = mwc.movie_id
WHERE 
    tr.production_year IS NOT NULL
ORDER BY 
    tr.production_year DESC, tr.title;

