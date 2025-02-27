WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT a.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
), FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        mh.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        MovieKeywords mh ON rm.title = mh.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keyword_count, 0) AS keyword_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.title = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    mi.info IS NOT NULL OR mk.keyword_count > 0
ORDER BY 
    fm.production_year DESC, 
    keyword_count DESC;
