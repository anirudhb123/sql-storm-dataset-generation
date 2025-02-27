WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT ak.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ak ON mk.keyword_id = ak.id
    GROUP BY 
        t.id
),
RankedReview AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.actors,
        m.keywords,
        ROW_NUMBER() OVER (ORDER BY m.cast_count DESC, m.production_year DESC) AS rank
    FROM 
        RankedMovies m
)
SELECT 
    r.rank,
    r.title,
    r.production_year,
    r.cast_count,
    r.actors,
    r.keywords
FROM 
    RankedReview r
WHERE 
    r.rank <= 10
ORDER BY 
    r.rank;
