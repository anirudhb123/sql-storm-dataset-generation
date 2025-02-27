WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        AVG(CASE WHEN ti.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS has_info_type
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type ti ON mi.info_type_id = ti.id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        rm.has_info_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.aka_names, rm.has_info_type
)
SELECT 
    *,
    CASE 
        WHEN has_info_type = 1 THEN 'Yes'
        ELSE 'No'
    END AS contains_info,
    CASE 
        WHEN cast_count > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    KeywordedMovies
ORDER BY 
    production_year DESC, cast_count DESC;
