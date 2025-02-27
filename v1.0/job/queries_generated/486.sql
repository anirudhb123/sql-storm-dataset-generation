WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COALESCE(MAX(ci.role_id), 0) AS max_role_id
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        role_type ci ON c.role_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.max_role_id,
    COALESCE(ks.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordStats ks ON md.movie_id = ks.movie_id
WHERE 
    md.cast_count > 5
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC
LIMIT 10;

-- Additional stats
SELECT 
    md.movie_id,
    PERCENT_RANK() OVER (ORDER BY md.cast_count) AS cast_rank,
    CASE 
        WHEN md.max_role_id IS NULL THEN 'Undefined Role'
        ELSE 'Defined Role'
    END AS role_status
FROM 
    MovieDetails md
WHERE 
    EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = md.movie_id AND ci.note IS NOT NULL
    )
ORDER BY 
    cast_rank ASC;
