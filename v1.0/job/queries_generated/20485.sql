WITH MovieData AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actors,
        keyword_count,
        company_count,
        rn
    FROM 
        MovieData
    WHERE 
        production_year IS NOT NULL
      AND
        keyword_count > 2
      AND
        company_count > 0
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.actors,
    COALESCE(f.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN f.rn <= 5 THEN 'Top Production Year'
        ELSE 'Other'
    END AS production_category
FROM 
    FilteredMovies f
WHERE 
    EXISTS (
        SELECT 1 FROM cast_info ci 
        WHERE ci.movie_id = f.title_id 
        AND ci.note IS NOT NULL
    )
ORDER BY 
    f.production_year DESC,
    f.title;
