WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS title_kind,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, kt.kind, t.production_year
    ORDER BY 
        company_count DESC,
        t.production_year DESC
    LIMIT 20
), popular_actors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        movie_count > 10
    ORDER BY 
        movie_count DESC
    LIMIT 10
), movie_info_details AS (
    SELECT 
        mi.movie_id,
        mi.info,
        it.info AS info_type
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        mi.notes IS NOT NULL
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Year,
    rt.title_kind AS Kind,
    pa.name AS Actor_Name,
    pa.movie_count AS Total_Movies_Acted,
    COUNT(mk.keyword) AS Keyword_Count,
    GROUP_CONCAT(DISTINCT mk.keyword ORDER BY mk.keyword) AS Keywords,
    GROUP_CONCAT(DISTINCT mid.info_type) AS Info_Types,
    MAX(mid.info) AS Latest_Info
FROM 
    ranked_titles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    aka_name pa ON ci.person_id = pa.person_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    movie_info_details mid ON rt.title_id = mid.movie_id
WHERE 
    pa.name IN (SELECT name FROM popular_actors)
GROUP BY 
    rt.title_id, pa.name, rt.production_year, rt.title_kind, pa.movie_count
ORDER BY 
    rt.production_year DESC, pa.movie_count DESC;
