WITH Recursive_CTE AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        c.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rn,
        ci.kind AS company_type
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
),
Movie_Info_Union AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mi.info AS movie_info,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY mi.info_type_id) AS info_rn
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Cast%')
),
Qualified_Cast AS (
    SELECT 
        r.cast_id,
        r.movie_id,
        r.person_id,
        mk.keyword AS movie_keyword,
        COALESCE(NULLIF(k.keyword, ''), 'No Keyword') AS final_keyword
    FROM 
        Recursive_CTE r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
Final_Output AS (
    SELECT 
        a.title,
        GROUP_CONCAT(DISTINCT qc.final_keyword) AS combined_keywords,
        COUNT(DISTINCT qc.person_id) AS total_actors,
        AVG(CASE WHEN mn.info IS NOT NULL THEN 1 ELSE 0 END) AS actor_info_percentage
    FROM 
        aka_title a
    LEFT JOIN 
        Qualified_Cast qc ON a.id = qc.movie_id
    LEFT JOIN 
        Movie_Info_Union mn ON a.id = mn.movie_id
    GROUP BY 
        a.id, a.title
)
SELECT 
    fo.title,
    fo.combined_keywords,
    fo.total_actors,
    fo.actor_info_percentage,
    CASE WHEN fo.total_actors > 0 THEN 'Yes' ELSE 'No' END AS has_actors
FROM 
    Final_Output fo
WHERE 
    fo.actor_info_percentage > 0.5
ORDER BY 
    fo.total_actors DESC, 
    fo.title;

