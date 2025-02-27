WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(mi.info_type_id) AS average_info_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.average_info_type
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
InfoSummary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT pi.info, ', ') AS person_info_summary,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        person_info pi ON pi.info_type_id = mi.info_type_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.average_info_type,
    isum.person_info_summary,
    isum.movie_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    InfoSummary isum ON tm.movie_id = isum.movie_id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
