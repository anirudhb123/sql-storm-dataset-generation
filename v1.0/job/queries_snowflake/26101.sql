
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mc.company_id) DESC) AS rank_by_company_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_company_count <= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    LISTAGG(f.keyword, ', ') WITHIN GROUP (ORDER BY f.keyword) AS keywords
FROM 
    FilteredMovies f
GROUP BY 
    f.movie_id, f.title, f.production_year
ORDER BY 
    f.production_year DESC, f.movie_id;
