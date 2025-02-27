
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies 
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
),
GenreCount AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT kt.id) AS genre_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        t.id
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actor_names,
        md.keywords,
        md.companies,
        gc.genre_count
    FROM 
        MovieDetails md
    JOIN 
        GenreCount gc ON md.movie_id = gc.movie_id
)
SELECT 
    *,
    CASE 
        WHEN genre_count > 5 THEN 'Action Packed'
        WHEN genre_count BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Niche'
    END AS movie_category
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    genre_count DESC;
