WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    LEFT JOIN 
        aka_name c ON b.person_id = c.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
), 

MovieWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)

SELECT 
    mw.title,
    mw.production_year,
    mw.keywords,
    CASE 
        WHEN mw.cast_count IS NULL THEN 'No Cast Information'
        ELSE CAST(mw.cast_count AS TEXT)
    END AS cast_count,
    COALESCE(mw.rank, 'Not Ranked') AS rank
FROM 
    MovieWithKeywords mw
RIGHT JOIN 
    RankedMovies r ON mw.movie_id = r.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.rank;
