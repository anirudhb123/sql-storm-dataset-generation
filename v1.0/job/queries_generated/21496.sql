WITH MovieStats AS (
    SELECT 
        T.title,
        C.kind AS movie_kind,
        COUNT(CI.id) AS total_cast,
        AVG(CASE WHEN CI.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_presence,
        MIN(P.production_year) AS earliest_movie_year,
        MAX(P.production_year) AS latest_movie_year
    FROM 
        aka_title T
    JOIN 
        title P ON T.movie_id = P.id
    LEFT JOIN 
        cast_info CI ON P.id = CI.movie_id
    LEFT JOIN 
        kind_type C ON P.kind_id = C.id
    GROUP BY 
        T.title, C.kind
),
CompanyInfo AS (
    SELECT 
        MC.movie_id,
        GROUP_CONCAT(DISTINCT CN.name) AS company_names,
        COUNT(DISTINCT CT.kind) AS company_types_count
    FROM 
        movie_companies MC
    JOIN 
        company_name CN ON MC.company_id = CN.id
    JOIN 
        company_type CT ON MC.company_type_id = CT.id
    WHERE 
        CN.country_code IS NOT NULL
    GROUP BY 
        MC.movie_id
),
KeywordStats AS (
    SELECT 
        MK.movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword MK
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
)

SELECT 
    MS.title,
    MS.movie_kind,
    MS.total_cast,
    MS.avg_note_presence,
    CI.company_names,
    CI.company_types_count,
    KS.keywords_list,
    CASE 
        WHEN MS.earliest_movie_year IS NOT NULL THEN MS.earliest_movie_year 
        ELSE 'Unknown' 
    END AS first_release,
    CASE 
        WHEN MS.latest_movie_year IS NOT NULL THEN MS.latest_movie_year 
        ELSE 'Unknown' 
    END AS last_release
FROM 
    MovieStats MS
LEFT JOIN 
    CompanyInfo CI ON MS.movie_id = CI.movie_id
LEFT JOIN 
    KeywordStats KS ON MS.movie_id = KS.movie_id
WHERE 
    MS.total_cast > 0
    AND MS.avg_note_presence < 0.5
ORDER BY 
    MS.latest_movie_year DESC,
    MS.title ASC;

WITH RECURSIVE MovieLinks AS (
    SELECT 
        ML.movie_id,
        ML.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ML
    WHERE 
        ML.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel' LIMIT 1)

    UNION ALL

    SELECT 
        ML.movie_id,
        ML.linked_movie_id,
        depth + 1
    FROM 
        movie_link ML
    JOIN 
        MovieLinks M ON ML.movie_id = M.linked_movie_id
)

SELECT 
    M.title,
    COUNT(DISTINCT ML.linked_movie_id) AS sequel_count,
    MAX(ML.depth) AS max_depth
FROM 
    title M
LEFT JOIN 
    MovieLinks ML ON M.id = ML.movie_id
GROUP BY 
    M.title
HAVING 
    COUNT(DISTINCT ML.linked_movie_id) > 0
ORDER BY 
    sequel_count DESC, max_depth DESC;
