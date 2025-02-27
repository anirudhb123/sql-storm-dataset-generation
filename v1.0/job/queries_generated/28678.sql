WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000 -- Filter for more recent movies
    GROUP BY 
        a.id, a.title, a.production_year
),
TopRankedTitles AS (
    SELECT 
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedTitles
    WHERE 
        rank <= 10
)

SELECT 
    tt.title,
    tt.production_year,
    tt.cast_count,
    tt.aka_names,
    CASE 
        WHEN tt.cast_count > 5 THEN 'Popular'
        ELSE 'Niche'
    END AS title_category
FROM 
    TopRankedTitles tt
ORDER BY 
    tt.cast_count DESC, tt.production_year DESC;
