WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastRoles AS (
    SELECT 
        ca.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(ca.id) AS total_cast
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.movie_id
),
NullCheck AS (
    SELECT 
        c.movie_id,
        CASE 
            WHEN c.total_cast IS NULL THEN 'No cast information available'
            ELSE c.total_cast::text || ' cast members'
        END AS cast_info
    FROM 
        CastRoles c
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(nc.cast_info, 'Unknown') AS cast_info,
    CASE 
        WHEN rm.rank_by_year <= 3 THEN 'Recent'
        ELSE 'Classic'
    END AS movie_age_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    NullCheck nc ON rm.movie_id = nc.movie_id
WHERE 
    rm.production_year BETWEEN 1990 AND 2023
ORDER BY 
    rm.production_year DESC, rm.title
LIMIT 100;
