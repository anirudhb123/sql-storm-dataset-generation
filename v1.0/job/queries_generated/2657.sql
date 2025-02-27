WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COALESCE(mk.role_count, 0) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        MovieRoles mk ON m.id = mk.movie_id
), MovieKeywords AS (
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
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year IS NOT NULL AND 
    (rm.rank <= 5 OR mk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.rank;
