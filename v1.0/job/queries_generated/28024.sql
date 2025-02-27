WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(cn.name, 'Unknown') AS company_name,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year, cn.name
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.keywords,
        rm.company_name,
        rm.aka_names,
        rm.cast_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.cast_count DESC) AS rn
    FROM 
        RankedMovies rm
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.keywords,
    fm.company_name,
    fm.aka_names,
    fm.cast_count
FROM 
    FilteredMovies fm
WHERE 
    fm.rn <= 5
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
