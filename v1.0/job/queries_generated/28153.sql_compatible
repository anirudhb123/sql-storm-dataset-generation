
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

FinalBenchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.companies,
        md.keywords,
        cd.total_cast,
        cd.cast_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)

SELECT 
    fb.*,
    CASE 
        WHEN fb.total_cast > 10 THEN 'Ensemble Cast'
        WHEN fb.total_cast BETWEEN 5 AND 10 THEN 'Significant Cast'
        ELSE 'Minor Cast'
    END AS cast_size_category
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC, fb.total_cast DESC;
