WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalMovieStats AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        kd.keywords,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.actor_count DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
)
SELECT 
    fms.movie_id,
    fms.title,
    fms.production_year,
    fms.actor_count,
    COALESCE(fms.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN fms.actor_count > 10 THEN 'High Actor Count'
        WHEN fms.actor_count BETWEEN 5 AND 10 THEN 'Moderate Actor Count'
        ELSE 'Low Actor Count'
    END AS actor_count_category
FROM 
    FinalMovieStats fms
WHERE 
    fms.production_year >= 2000
ORDER BY 
    fms.rank;
