WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ',') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        ci.note,
        rt.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
)
SELECT 
    tt.title,
    tt.production_year,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    ci.total_cast,
    COUNT(DISTINCT ak.name) AS total_aka_names
FROM 
    RankedTitles tt
LEFT JOIN 
    TitleKeywords tk ON tt.id = tk.movie_id
LEFT JOIN 
    CastInfoWithRoles ci ON tt.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    tt.rank <= 5
GROUP BY 
    tt.title, tt.production_year, tk.keywords, ci.total_cast
ORDER BY 
    tt.production_year DESC, total_cast DESC;
