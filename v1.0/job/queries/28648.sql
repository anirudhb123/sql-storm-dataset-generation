WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

TopTitles AS (
    SELECT 
        title_id, 
        title, 
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5 
),

TitleKeywords AS (
    SELECT 
        mt.movie_id,
        mt.keyword_id,
        mk.keyword
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
),

TitleInfo AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        COUNT(tk.keyword_id) AS keyword_count
    FROM 
        TopTitles tt
    LEFT JOIN 
        TitleKeywords tk ON tk.movie_id = tt.title_id
    GROUP BY 
        tt.title_id, tt.title, tt.production_year
),

PersonRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
)

SELECT 
    ti.title,
    ti.production_year,
    ti.keyword_count,
    pr.actor_count,
    pr.actor_names
FROM 
    TitleInfo ti
LEFT JOIN 
    PersonRoles pr ON pr.movie_id = ti.title_id
ORDER BY 
    ti.production_year DESC, 
    ti.keyword_count DESC;