WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        MovieDetails m
    JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        cd.num_cast_members,
        cd.cast_names,
        CASE 
            WHEN md.production_year < 2010 THEN 'Classic'
            WHEN md.production_year BETWEEN 2010 AND 2019 THEN 'Modern'
            ELSE 'Recent'
        END AS era,
        COUNT(DISTINCT mc.company_id) AS num_production_companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, cd.num_cast_members, cd.cast_names
    ORDER BY 
        md.production_year DESC
)
SELECT 
    *,
    CONCAT(title, ' (', production_year, ') - Cast: ', num_cast_members, ' [' , STRING_AGG(DISTINCT keywords, ', '), ']') AS movie_summary
FROM 
    FinalResults;
