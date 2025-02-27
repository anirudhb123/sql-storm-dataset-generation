WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.title) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        string_agg(DISTINCT r.keyword, ', ') AS keywords_list,
        AVG(COALESCE(CAST(CASE WHEN ci.role_id IS NOT NULL AND ci.nr_order IS NOT NULL THEN 1 ELSE NULL END AS FLOAT), 0)) AS avg_cast_rank
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    GROUP BY 
        r.movie_id, r.title
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.keywords_list,
        md.avg_cast_rank,
        CASE 
            WHEN AVG(md.avg_cast_rank) >= 1.75 THEN 'High'
            WHEN AVG(md.avg_cast_rank) BETWEEN 1 AND 1.75 THEN 'Medium'
            ELSE 'Low'
        END AS cast_quality
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id, md.title, md.keywords_list, md.avg_cast_rank
    ORDER BY 
        md.avg_cast_rank DESC, md.title
)
SELECT 
    *
FROM 
    FinalResults
WHERE 
    cast_quality = 'High'
LIMIT 10;
