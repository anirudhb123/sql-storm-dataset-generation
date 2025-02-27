WITH MovieDetails AS (
    SELECT 
        a.title, 
        a.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT cc.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast c ON a.id = c.movie_id
    LEFT JOIN 
        cast_info cc ON c.subject_id = cc.id 
    WHERE 
        a.production_year IS NOT NULL AND
        a.production_year >= 2000
),
RankedMovies AS (
    SELECT 
        title, 
        production_year, 
        keyword, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year ASC) AS rank
    FROM 
        MovieDetails
),
TopMovies AS (
    SELECT 
        * 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.cast_count,
    COALESCE(pi.info, 'No Info') AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    person_info pi ON pi.person_id IN (
        SELECT 
            DISTINCT cc.person_id 
        FROM 
            cast_info cc
        JOIN 
            complete_cast cc2 ON cc.id = cc2.subject_id
        WHERE 
            cc2.movie_id IN (SELECT id FROM aka_title WHERE production_year = tm.production_year)
    )
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year;
