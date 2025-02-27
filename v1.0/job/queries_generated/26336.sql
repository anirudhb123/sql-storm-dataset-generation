WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(k.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), TopKeywords AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword
    FROM 
        RankedTitles
    WHERE 
        rank <= 3
), MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        ci.note AS cast_note
    FROM 
        TopKeywords tk
    JOIN 
        complete_cast cc ON cc.movie_id = tk.title_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = tk.title_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON ci.movie_id = tk.title_id AND ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL AND 
        ci.note NOT LIKE '%uncredited%'
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.company_type,
    COUNT(md.actor_name) AS actor_count,
    STRING_AGG(DISTINCT md.cast_note, '; ') AS cast_notes
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year, md.actor_name, md.company_type
ORDER BY 
    md.production_year DESC, 
    actor_count DESC;
