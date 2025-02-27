
WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        kind_type.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank
    FROM 
        title
    JOIN 
        kind_type ON title.kind_id = kind_type.id
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.title_kind
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        STRING_AGG(DISTINCT c.name, ',' ORDER BY c.name) AS cast_names,
        STRING_AGG(DISTINCT cn.name, ',' ORDER BY cn.name) AS company_names
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
)
SELECT 
    td.title AS Movie_Title,
    td.production_year AS Production_Year,
    td.cast_names AS Cast,
    td.company_names AS Production_Companies,
    tt.title_kind AS Title_Kind
FROM 
    MovieDetails td
JOIN 
    TopRankedTitles tt ON td.movie_id = tt.title_id
ORDER BY 
    td.production_year DESC, 
    td.title ASC;
