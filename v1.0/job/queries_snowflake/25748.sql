
WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
), 
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COALESCE LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role), 'No roles') AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    k.keyword AS Most_Popular_Keyword,
    cr.cast_count AS Number_of_Cast,
    cr.roles AS Roles_Played
FROM 
    RankedTitles t
JOIN 
    PopularKeywords k ON t.title_id = k.movie_id
JOIN 
    CastRoles cr ON t.title_id = cr.movie_id
WHERE 
    t.rank = 1 
ORDER BY 
    t.production_year DESC,
    cr.cast_count DESC;
