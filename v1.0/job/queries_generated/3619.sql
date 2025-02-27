WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS total_cast_members,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) OVER (PARTITION BY t.id) AS avg_order
    FROM 
        aka_title t 
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast_members,
        rm.avg_order,
        RANK() OVER (ORDER BY rm.total_cast_members DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.total_cast_members > 10
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year
    FROM 
        TopMovies tm
    WHERE 
        tm.rank <= 10
)
SELECT 
    fm.title,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = fm.movie_id)
GROUP BY 
    fm.movie_id, cn.name
ORDER BY 
    fm.production_year DESC;
