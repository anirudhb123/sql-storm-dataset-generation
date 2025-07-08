
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS row_num
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        LISTAGG(rm.keyword, ', ') WITHIN GROUP (ORDER BY rm.keyword) AS keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.row_num <= 5
    GROUP BY 
        rm.title, rm.production_year
),
CastInfo AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        FilteredMovies fm ON ci.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1)
    GROUP BY 
        ci.movie_id
)
SELECT 
    fm.title, 
    fm.production_year, 
    fm.keywords, 
    ci.actor_count
FROM 
    FilteredMovies fm
JOIN 
    CastInfo ci ON (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1) = ci.movie_id
ORDER BY 
    fm.production_year DESC, 
    ci.actor_count DESC;
