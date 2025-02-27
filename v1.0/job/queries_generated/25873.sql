WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieRoles AS (
    SELECT 
        m.title,
        c.nr_order,
        CONCAT(a.name, ' as ', r.role) AS full_cast
    FROM 
        RankedMovies AS m
    JOIN 
        complete_cast AS cc ON m.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.person_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    WHERE 
        m.rank <= 5
),
Filmography AS (
    SELECT 
        m.title,
        STRING_AGG(mr.full_cast, ', ') AS cast
    FROM 
        MovieRoles AS mr
    GROUP BY 
        m.title
)
SELECT 
    f.title,
    f.cast,
    AVG(m.production_year) AS average_year
FROM 
    Filmography AS f
JOIN 
    title AS t ON f.title = t.title
JOIN 
    RankedMovies AS rm ON t.id = rm.id
GROUP BY 
    f.title, f.cast
ORDER BY 
    average_year DESC;
