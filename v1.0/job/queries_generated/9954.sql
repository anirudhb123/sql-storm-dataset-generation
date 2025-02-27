WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_names,
        rm.info_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keyword,
    fm.cast_names,
    fm.info_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;
