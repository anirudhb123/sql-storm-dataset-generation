WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_title ak ON m.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND cn.country_code IN ('USA', 'UK', 'CAN') 
    GROUP BY 
        m.id
),
RankedMoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        rm.keywords,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.aka_names, rm.keywords
),
FinalResults AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.aka_names,
        r.keywords,
        r.roles,
        CASE 
            WHEN r.cast_count > 10 THEN 'Large Ensemble' 
            WHEN r.cast_count BETWEEN 5 AND 10 THEN 'Medium Ensemble' 
            ELSE 'Small Cast' 
        END AS cast_size
    FROM 
        RankedMoviesWithRoles r
)
SELECT 
    * 
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    cast_count DESC 
LIMIT 50;
