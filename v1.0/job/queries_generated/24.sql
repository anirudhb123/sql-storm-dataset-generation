WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_produced
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

RatedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.avg_order,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.total_cast, md.avg_order
)

SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.avg_order,
    COALESCE(rm.info_count, 0) AS info_count,
    CASE 
        WHEN rm.total_cast > 20 THEN 'Large Cast'
        WHEN rm.total_cast BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    RatedMovies rm
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.avg_order > (SELECT AVG(avg_order) FROM RatedMovies) -- correlated subquery
GROUP BY 
    rm.title, rm.production_year, rm.total_cast, rm.avg_order
ORDER BY 
    rm.production_year DESC, rm.title;
