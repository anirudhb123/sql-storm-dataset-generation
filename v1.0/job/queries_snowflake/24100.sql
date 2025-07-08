
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredTitles AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        mk.keywords,
        COALESCE(COUNT(ca.id), 0) AS cast_count,
        MAX(CASE WHEN ca.person_role_id IS NOT NULL THEN 'Has Role' ELSE 'No Role' END) AS role_status
    FROM 
        RankedMovies tm
    LEFT JOIN 
        cast_info ca ON ca.movie_id = tm.title_id
    LEFT JOIN 
        MovieKeywords mk ON tm.title_id = mk.movie_id
    WHERE 
        tm.rn <= 5
    GROUP BY 
        tm.title_id, tm.title, tm.production_year, mk.keywords
)
SELECT 
    ft.title,
    ft.production_year,
    ft.keywords,
    ft.cast_count,
    ft.role_status,
    CASE 
        WHEN ft.keywords IS NULL THEN 'No Keywords Found'
        ELSE ft.keywords
    END AS keyword_status
FROM 
    FilteredTitles ft
WHERE 
    (ft.cast_count > 0 OR ft.role_status = 'Has Role')
ORDER BY 
    ft.production_year DESC, 
    ft.cast_count DESC,
    ft.title;
