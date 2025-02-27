WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS name_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
MovieDetails AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        tk.keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        RankedTitles tt
    LEFT JOIN 
        TitleKeywords tk ON tt.title_id = tk.movie_id
    LEFT JOIN 
        cast_info ci ON tt.title_id = ci.movie_id
    GROUP BY 
        tt.title_id, tt.title, tt.production_year, tk.keywords
)

SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.actor_count
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 5
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
