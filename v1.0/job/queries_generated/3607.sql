WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
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
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.kind_id,
    cd.actor_name,
    cd.role_type,
    cd.cast_order,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_title = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_title = mk.movie_id
WHERE 
    rm.year_rank <= 5
    AND (cd.role_type IS NOT NULL OR cd.actor_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    cd.cast_order;
