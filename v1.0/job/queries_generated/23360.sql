WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rn,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT d.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    LEFT JOIN 
        movie_companies e ON a.id = e.movie_id
    LEFT JOIN 
        company_name c ON e.company_id = c.id
    LEFT JOIN 
        complete_cast f ON a.id = f.movie_id
    LEFT JOIN 
        person_info d ON f.subject_id = d.person_id
    WHERE 
        a.production_year IS NOT NULL
        AND (a.production_year > 2000 OR a.production_year IS NULL)
    GROUP BY 
        a.title, a.production_year, c.name
),

MovieKeywords AS (
    SELECT 
        k.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title k
    LEFT JOIN 
        movie_keyword mk ON k.id = mk.movie_id
    GROUP BY 
        k.id
),

FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year, 
        rm.company_name, 
        rm.cast_count,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.movie_id
    WHERE 
        rm.rn = 1 AND 
        rm.cast_count > 5
)

SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    COALESCE(fm.keywords, 'No keywords available') AS keywords_info
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year IS NOT NULL 
    OR fm.company_name IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.title;
