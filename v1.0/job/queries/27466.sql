
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name AS ak ON cc.subject_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        r.role AS person_role,
        COUNT(c.person_role_id) AS role_count
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.keywords,
    pr.person_role,
    pr.role_count
FROM 
    RankedMovies AS rm
LEFT JOIN 
    PersonRoles AS pr ON rm.movie_id = pr.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    pr.role_count DESC;
