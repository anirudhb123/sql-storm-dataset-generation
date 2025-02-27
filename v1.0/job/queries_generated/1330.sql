WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.id
),
TitleKeyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
PersonRoles AS (
    SELECT 
        p.id AS person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        person_info pi
    JOIN 
        cast_info ci ON pi.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        p.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    tk.keywords,
    pr.movie_count,
    pr.roles
FROM 
    RankedMovies rm
LEFT JOIN 
    TitleKeyword tk ON rm.movie_id = tk.movie_id
LEFT JOIN 
    PersonRoles pr ON pr.movie_count > 10
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.rank;
