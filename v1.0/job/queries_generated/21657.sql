WITH RecursiveTitleCTE AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'Unknown') as keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) as keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        t.production_year IS NOT NULL 
    UNION ALL
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        tt.keyword,
        tt.keyword_rank
    FROM 
        RecursiveTitleCTE rt
    JOIN 
        movie_link ml ON rt.title_id = ml.movie_id 
    JOIN 
        title tt ON ml.linked_movie_id = tt.id
    WHERE 
        rt.keyword_rank < 2
),
FilteredCast AS (
    SELECT 
        ci.id,
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        COUNT(DISTINCT ci.note) AS distinct_notes,
        MAX(CASE WHEN ci.note IS NULL THEN 'No Note' ELSE ci.note END) as latest_note
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        ci.id, ci.person_id, ci.movie_id, ci.role_id
),
PopularMovies AS (
    SELECT 
        tt.title_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        RecursiveTitleCTE tt
    JOIN 
        movie_keyword mk ON tt.title_id = mk.movie_id
    WHERE 
        tt.production_year > 2000
    GROUP BY 
        tt.title_id
    HAVING 
        COUNT(DISTINCT mk.keyword_id) > 3
),
FinalResults AS (
    SELECT 
        r.title,
        r.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(f.distinct_notes) AS total_distinct_notes,
        SUM(f.latest_note IS NOT NULL::int) AS total_notes
    FROM 
        RecursiveTitleCTE r
    LEFT JOIN 
        cast_info c ON r.title_id = c.movie_id
    LEFT JOIN 
        FilteredCast f ON c.id = f.id
    LEFT JOIN 
        PopularMovies pm ON r.title_id = pm.title_id
    WHERE 
        pm.keyword_count IS NOT NULL
    GROUP BY 
        r.title, r.production_year
    ORDER BY 
        r.production_year DESC, total_cast DESC
)
SELECT 
    title,
    production_year,
    total_cast,
    total_distinct_notes,
    CASE 
        WHEN total_notes > 0 THEN 'Notes Present' 
        ELSE 'No Notes' 
    END AS notes_presence,
    md5sum
FROM 
    FinalResults fr
LEFT JOIN 
    aka_title at ON fr.title = at.title
WHERE 
    at.md5sum IS NOT NULL
ORDER BY 
    total_cast DESC
FETCH FIRST 10 ROWS ONLY;
