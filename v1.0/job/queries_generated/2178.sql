WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY k.keyword) AS rn,
        COUNT(m.id) OVER (PARTITION BY t.id) AS company_count,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_with_notes
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        rn,
        company_count,
        cast_with_notes
    FROM 
        RankedMovies
    WHERE 
        (production_year IS NOT NULL AND production_year > 2000)
        OR (cast_with_notes > 5 AND company_count <= 3)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.company_count,
    CASE 
        WHEN fm.cast_with_notes IS NULL THEN 'No notes'
        ELSE 'Notes available'
    END AS note_status
FROM 
    FilteredMovies fm
WHERE 
    fm.rn = 1
ORDER BY 
    fm.production_year DESC, 
    fm.title;
