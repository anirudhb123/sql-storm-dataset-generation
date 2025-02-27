
WITH MovieStats AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_order
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.title, mt.production_year
),
GenreKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS count_per_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
TopMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.avg_order,
        ROW_NUMBER() OVER (ORDER BY ms.total_cast DESC) AS rn
    FROM 
        MovieStats ms
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(gk.keywords, 'No Keywords') AS keywords,
    COALESCE(cr.count_per_role, 0) AS count_per_role,
    tm.total_cast,
    tm.avg_order
FROM 
    TopMovies tm
LEFT JOIN 
    GenreKeywords gk ON tm.title = (SELECT title FROM aka_title WHERE id = gk.movie_id)
LEFT JOIN 
    CastInfoWithRoles cr ON tm.title = (SELECT title FROM aka_title WHERE id = cr.movie_id)
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.total_cast DESC, tm.avg_order ASC;
