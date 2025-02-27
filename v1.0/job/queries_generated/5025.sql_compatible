
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL 
    GROUP BY 
        a.id, t.title, t.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS year_rank
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.company_name,
    f.keyword_count
FROM 
    FilteredMovies f
WHERE 
    f.year_rank <= 3
ORDER BY 
    f.production_year, f.keyword_count DESC;
