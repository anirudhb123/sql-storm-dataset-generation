WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.info_count, 
        rm.keyword_count, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)

SELECT 
    fm.title,
    fm.production_year,
    fm.info_count,
    fm.keyword_count,
    fm.cast_count,
    ak.name AS aka_name,
    cn.name AS company_name
FROM 
    FilteredMovies fm
LEFT JOIN 
    aka_title at ON fm.movie_id = at.movie_id
LEFT JOIN 
    aka_name ak ON at.id = ak.id
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
ORDER BY 
    fm.cast_count DESC;
