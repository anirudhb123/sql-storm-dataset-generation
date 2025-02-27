WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS number_of_actors
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id, ci.role_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(ck.kind, 'Unknown Kind') AS movie_kind,
        COUNT(DISTINCT c.id) AS number_of_companies,
        MIN(p.info) AS first_info,
        MAX(p.info) AS last_info
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        person_info p ON m.movie_id = p.person_id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        comp_cast_type ck ON ci.person_role_id = ck.id
    GROUP BY 
        m.movie_id, k.keyword, ck.kind
),
FinalSelection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rd.number_of_actors,
        md.keyword,
        md.movie_kind,
        md.number_of_companies,
        md.first_info,
        md.last_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles rd ON rm.movie_id = rd.movie_id
    LEFT JOIN 
        MovieDetails md ON rm.movie_id = md.movie_id
    WHERE 
        (md.number_of_companies > 0 OR md.keyword IS NOT NULL)
        AND (md.first_info IS NULL OR md.last_info IS NOT NULL)
        AND rm.rn < 5
)
SELECT 
    f.title,
    f.production_year,
    f.number_of_actors,
    f.keyword,
    f.movie_kind,
    f.number_of_companies,
    COALESCE(f.first_info, 'No Info Available') AS detailed_info
FROM 
    FinalSelection f
WHERE 
    f.movie_kind IN ('Feature Film', 'Short Film') 
    AND f.number_of_actors > 10
ORDER BY 
    f.production_year DESC, 
    f.title ASC
LIMIT 50;
