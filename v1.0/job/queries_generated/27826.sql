WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
TitleDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        STRING_AGG(rt.keyword, ', ') AS keywords
    FROM 
        RankedTitles rt
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
),
CastAndRoles AS (
    SELECT 
        ti.title_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        TitleDetails ti
    LEFT JOIN 
        complete_cast cc ON ti.title_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ti.title_id
),
FinalBenchmark AS (
    SELECT 
        td.title,
        td.production_year,
        ca.cast_count,
        ca.roles,
        td.keywords
    FROM 
        TitleDetails td
    JOIN 
        CastAndRoles ca ON td.title_id = ca.title_id
    ORDER BY 
        td.production_year DESC, 
        ca.cast_count DESC
)

SELECT 
    title,
    production_year,
    cast_count,
    roles,
    keywords
FROM 
    FinalBenchmark
WHERE 
    production_year BETWEEN 1990 AND 2023
LIMIT 100;
