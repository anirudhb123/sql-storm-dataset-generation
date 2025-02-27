WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedByCastCount AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC) AS cast_rank
    FROM 
        RankedMovies
),
FilteredMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.aka_names,
        r.keyword_count
    FROM 
        RankedByCastCount r
    WHERE 
        r.cast_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.aka_names,
    f.keyword_count,
    ct.kind AS company_type
FROM 
    FilteredMovies f
JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    f.keyword_count DESC, 
    f.cast_count DESC;
