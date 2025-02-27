WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        kt.kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rn
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year IS NOT NULL AND
        kt.kind LIKE '%Drama%' 
),
ImprovedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(CASE WHEN char.name IS NOT NULL THEN 1 ELSE 0 END) AS has_char_name,
        SUM(CASE WHEN cpt.kind IS NOT NULL THEN 1 ELSE 0 END) AS comp_cast_types
    FROM 
        cast_info ci
    LEFT JOIN 
        char_name char ON ci.person_id = char.imdb_id
    LEFT JOIN 
        comp_cast_type cpt ON ci.person_role_id = cpt.id
    GROUP BY 
        ci.movie_id
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
    rm.title,
    rm.production_year,
    rm.kind,
    ic.cast_count,
    ic.has_char_name,
    mk.keywords,
    COALESCE(NULLIF(mk.keywords, ''), 'No Keywords') AS keyword_display,
    COUNT(*) FILTER (WHERE ic.cast_count > 10) OVER () AS popular_movie_count,
    CASE 
        WHEN ic.has_char_name = 1 THEN 'Has Character Names'
        ELSE 'No Character Names'
    END AS character_name_status
FROM 
    RankedMovies rm
JOIN 
    ImprovedCast ic ON rm.title = (
        SELECT 
            a.title 
        FROM 
            aka_title a 
        WHERE 
            a.movie_id = ic.movie_id 
        LIMIT 1
    )
LEFT JOIN 
    MovieKeywords mk ON rm.title = (
        SELECT 
            a.title 
        FROM 
            aka_title a 
        WHERE 
            a.movie_id = mk.movie_id 
        LIMIT 1
    )
WHERE 
    rm.rn <= 5 OR rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
