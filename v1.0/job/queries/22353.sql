WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.person_id,
        c.movie_id,
        ca.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        comp_cast_type ca ON c.person_role_id = ca.id
    WHERE 
        c.note IS NULL
),
TitleKeywordCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mt.movie_id = mk.movie_id
    GROUP BY 
        mt.movie_id
),
YearlyKeywordRank AS (
    SELECT
        tt.production_year,
        COUNT(tkc.keyword_count) AS total_keywords,
        RANK() OVER (ORDER BY COUNT(tkc.keyword_count) DESC) AS production_year_rank
    FROM 
        RankedTitles tt
    LEFT JOIN 
        TitleKeywordCounts tkc ON tt.title_id = tkc.movie_id
    GROUP BY 
        tt.production_year
)
SELECT 
    at.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    cd.role_type,
    COALESCE(yk.total_keywords, 0) AS total_keywords,
    yk.production_year_rank
FROM 
    aka_name at
JOIN 
    CastDetails cd ON at.person_id = cd.person_id
JOIN 
    aka_title rt ON cd.movie_id = rt.id
LEFT JOIN 
    YearlyKeywordRank yk ON rt.production_year = yk.production_year
WHERE 
    rt.production_year BETWEEN 2000 AND 2023
    AND cd.role_order = 1  
ORDER BY 
    rt.production_year DESC, at.name;