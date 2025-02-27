WITH RecursiveCTE AS (
    SELECT 
        ak.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ak.name) AS name_order,
        COALESCE(STRING_AGG(DISTINCT c.note, ', ') FILTER (WHERE c.note IS NOT NULL), 'No Notes') AS notes,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        ak.name, t.title, t.production_year
),

MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        COUNT(k.id) FILTER (WHERE k.keyword IS NOT NULL) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, k.keyword
),

FilteredTitles AS (
    SELECT 
        rc.aka_name,
        rc.movie_title,
        rc.production_year,
        rc.name_order,
        rc.notes,
        rc.cast_count,
        mwk.keyword,
        ROW_NUMBER() OVER (PARTITION BY rc.production_year ORDER BY rc.cast_count DESC) AS rank_by_cast
    FROM 
        RecursiveCTE rc
    LEFT JOIN 
        MoviesWithKeywords mwk ON rc.movie_title = mwk.title
    WHERE 
        rc.cast_count > 0
    
    AND rc.aka_name IS NOT NULL AND rc.aka_name != 'Unknown'
)

SELECT 
    ft.movie_title,
    ft.production_year,
    ft.aka_name,
    ft.notes,
    ft.cast_count,
    COALESCE(ft.keyword, 'No Keywords') AS keyword,
    ft.rank_by_cast
FROM 
    FilteredTitles ft
WHERE 
    ft.rank_by_cast <= 5
AND 
    (ft.production_year IS NOT NULL) 
ORDER BY 
    ft.production_year, ft.cast_count DESC;