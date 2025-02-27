WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast 
    FROM 
        cast_info c
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(r.production_year, 0) AS production_year,
        COALESCE(f.total_cast, 0) AS total_cast,
        COUNT(mk.keyword) AS keyword_count 
    FROM 
        aka_title m
    LEFT JOIN 
        RankedTitles r ON m.id = r.title_id AND r.title_rank = 1
    LEFT JOIN 
        FilteredCast f ON m.id = f.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, r.production_year, f.total_cast
),
FinalResults AS (
    SELECT 
        md.movie_title,
        CASE 
            WHEN md.production_year = 0 THEN 'Unknown Year'
            ELSE md.production_year::text
        END AS production_year,
        md.total_cast,
        md.keyword_count,
        ROW_NUMBER() OVER (ORDER BY md.total_cast DESC, md.keyword_count DESC) AS rank
    FROM 
        MovieDetails md
    WHERE 
        md.total_cast > 0
)
SELECT 
    f.movie_title,
    f.production_year,
    f.total_cast,
    f.keyword_count,
    CASE 
        WHEN f.rank BETWEEN 1 AND 10 THEN 'Top 10'
        WHEN f.rank BETWEEN 11 AND 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS rank_category
FROM 
    FinalResults f
WHERE 
    f.keyword_count IS NOT NULL
    AND f.total_cast IS NOT NULL
ORDER BY 
    f.rank;
