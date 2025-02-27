
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.id) DESC) AS rank
    FROM 
        aka_title t
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),
TotalCastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)

SELECT 
    tr.title,
    tr.production_year,
    tr.keyword_count,
    tci.total_cast_members,
    ak.name AS actor_name,
    cn.name AS production_company,
    r.role
FROM 
    TopRankedTitles tr
    LEFT JOIN TotalCastInfo tci ON tr.title_id = tci.movie_id
    LEFT JOIN cast_info ci ON tr.title_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_companies mc ON tr.title_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN role_type r ON ci.role_id = r.id
WHERE 
    tr.production_year >= 2000
    AND cn.country_code = 'USA'
ORDER BY 
    tr.production_year DESC, 
    tr.keyword_count DESC;
