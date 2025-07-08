
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS movie_keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        rm.movie_keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5  
),
MovieInfo AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.total_cast,
        fm.cast_names,
        fm.movie_keywords,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS additional_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.movie_id = mi.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.cast_names, fm.movie_keywords
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.total_cast,
    m.cast_names,
    m.movie_keywords,
    m.additional_info
FROM 
    MovieInfo m
ORDER BY 
    m.production_year DESC, 
    m.total_cast DESC;
