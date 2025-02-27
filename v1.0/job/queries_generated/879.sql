WITH MovieStats AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        AVG(CASE WHEN cc.nr_order IS NOT NULL THEN cc.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year > 2000
    GROUP BY 
        at.id
),
TopMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.avg_order,
        ROW_NUMBER() OVER (ORDER BY ms.total_cast DESC) AS rank
    FROM 
        MovieStats ms
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_order,
    CASE 
        WHEN tm.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS category,
    COALESCE(NULLIF(tm.cast_names, ''), 'No Cast') AS cast_names
FROM 
    TopMovies tm
WHERE 
    tm.avg_order > 0
ORDER BY 
    tm.rank;
