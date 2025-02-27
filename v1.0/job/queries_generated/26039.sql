WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(k.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(k.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(ci.person_role_id, rt.role) AS role,
        GROUP_CONCAT(DISTINCT an.name) AS actors,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type rt ON ci.person_role_id = rt.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        tm.title, tm.production_year, ci.person_role_id, rt.role
)
SELECT 
    md.title,
    md.production_year,
    md.role,
    md.actors,
    md.companies
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
