WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', rt.role), ', ') AS cast_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieInfoWithKeywords AS (
    SELECT 
        mi.movie_id,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        movie_info mi
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON mi.movie_id = mk.movie_id
)
SELECT 
    tr.title,
    tr.production_year,
    c.total_cast,
    c.cast_roles,
    COALESCE(mik.keywords, 'No Keywords') AS keywords
FROM 
    TopRankedMovies tr
LEFT JOIN 
    CastInfoWithRoles c ON tr.movie_id = c.movie_id
LEFT JOIN 
    MovieInfoWithKeywords mik ON tr.movie_id = mik.movie_id
ORDER BY 
    tr.production_year DESC, 
    tr.title ASC;
