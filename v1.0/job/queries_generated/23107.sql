WITH RecursiveTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),

ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        RANK() OVER (PARTITION BY a.person_id ORDER BY COUNT(c.movie_id) DESC) AS role_rank,
        COALESCE(MAX(c.nr_order), 0) AS highest_order
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name, c.movie_id
),

CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.subject_id) AS total_cast,
        SUM(CASE WHEN cc.status_id IS NULL THEN 1 ELSE 0 END) AS missing_status_count
    FROM 
        complete_cast AS cc
    GROUP BY 
        cc.movie_id
)

SELECT 
    rti.title,
    rti.production_year,
    ad.name AS lead_actor,
    ad.role_rank,
    c.total_cast,
    c.missing_status_count,
    CASE
        WHEN rti.keyword_rank IS NULL THEN 'No Keywords'
        ELSE STRING_AGG(rti.keyword, ', ' ORDER BY rti.keyword_rank)
    END AS keywords_summary,
    COALESCE(NULLIF(MAX(a.md5sum), ''), 'No MD5 Sum') AS movie_md5sum
FROM 
    RecursiveTitleInfo AS rti
LEFT JOIN 
    ActorDetails AS ad ON rti.title_id = ad.movie_id AND ad.role_rank = 1
LEFT JOIN 
    CompleteCast AS c ON rti.title_id = c.movie_id
LEFT JOIN 
    aka_title AS a ON rti.title_id = a.id
GROUP BY 
    rti.title_id, rti.title, rti.production_year, ad.name, ad.role_rank, c.total_cast, c.missing_status_count
HAVING 
    SUM(COALESCE(1, NULLIF(ad.highest_order, 0))) > 1
ORDER BY 
    rti.production_year DESC, rti.title;
