
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        cd.actors,
        cd.total_cast,
        CASE 
            WHEN md.production_year < 2010 THEN 'Classic'
            WHEN md.production_year BETWEEN 2010 AND 2019 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    era,
    COUNT(*) AS movie_count,
    AVG(total_cast) AS avg_cast,
    COUNT(DISTINCT keywords) AS unique_keywords
FROM 
    FinalBenchmark
GROUP BY 
    era
ORDER BY 
    movie_count DESC;
