WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        kind_id, 
        cast_count,
        aka_names, 
        RANK() OVER (ORDER BY cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    t1.title AS movie_title,
    t1.production_year,
    ct.kind AS genre,
    t1.cast_count,
    t1.aka_names,
    STRING_AGG(DISTINCT p.info, '; ') AS person_info
FROM 
    TopMovies t1
JOIN 
    kind_type ct ON t1.kind_id = ct.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t1.id
LEFT JOIN 
    person_info p ON cc.subject_id = p.person_id
WHERE 
    t1.movie_rank <= 10
GROUP BY 
    t1.title, t1.production_year, ct.kind, t1.cast_count, t1.aka_names
ORDER BY 
    t1.cast_count DESC;
