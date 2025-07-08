
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_count_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRoles AS (
    SELECT 
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.role_count_rank <= 5
),
MovieDetails AS (
    SELECT 
        tr.title,
        m.name AS company_name,
        k.keyword
    FROM 
        TopRoles tr
    JOIN 
        aka_title at ON at.title = tr.title
    JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    td.title,
    td.company_name,
    LISTAGG(td.keyword, ', ') WITHIN GROUP (ORDER BY td.keyword) AS keywords
FROM 
    MovieDetails td
GROUP BY 
    td.title, td.company_name
ORDER BY 
    td.title;
