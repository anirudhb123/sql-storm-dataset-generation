WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        r.role AS role,
        rc.kind AS role_type
    FROM 
        complete_cast m
    JOIN 
        aka_name a ON m.subject_id = a.person_id
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id AND ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        comp_cast_type rc ON CI.person_role_id = rc.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CONCAT(it.info, ': ', mi.info), '; ') AS additional_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.actor_name,
    mc.role,
    mk.keywords,
    mi.additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
