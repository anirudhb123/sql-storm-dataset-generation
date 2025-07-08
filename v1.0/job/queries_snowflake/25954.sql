
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year,
        a.name AS author_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, a.name) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_name a ON a.id = (SELECT id FROM aka_name WHERE person_id IN (SELECT id FROM name WHERE imdb_id = t.id) LIMIT 1)
    WHERE 
        k.keyword ILIKE '%adventure%' 
        AND mi.info ILIKE '%fun%'
),
GroupedByYear AS (
    SELECT 
        production_year,
        COUNT(title_id) AS title_count,
        LISTAGG(title, ', ') WITHIN GROUP (ORDER BY title) AS titles
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
    GROUP BY 
        production_year
),
FinalOutput AS (
    SELECT 
        g.production_year,
        g.title_count,
        g.titles,
        CASE 
            WHEN g.title_count > 0 THEN 'Has Titles'
            ELSE 'No Titles'
        END AS title_status
    FROM 
        GroupedByYear g
    ORDER BY 
        production_year DESC
)
SELECT 
    *
FROM 
    FinalOutput;
