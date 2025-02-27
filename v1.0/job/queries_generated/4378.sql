WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        AVG(p.rating) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(rating) AS rating 
        FROM 
            movie_info 
        WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
        GROUP BY movie_id) p ON t.id = p.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    c.kind AS company_type,
    STRING_AGG(cn.name, ', ') AS company_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
GROUP BY 
    fm.title, fm.production_year, c.kind
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
