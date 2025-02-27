WITH MovieStatistics AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COALESCE(MIN(t.production_year), 0) AS earliest_release,
        COALESCE(MAX(t.production_year), 0) AS latest_release
    FROM 
        aka_title AS a
    JOIN 
        cast_info AS ci ON a.id = ci.movie_id
    JOIN 
        title AS t ON a.movie_id = t.id
    GROUP BY 
        a.title
),
KeywordStats AS (
    SELECT 
        kt.keyword AS keyword,
        COUNT(DISTINCT mk.movie_id) AS movies_count
    FROM 
        keyword AS kt
    JOIN 
        movie_keyword AS mk ON kt.id = mk.keyword_id
    GROUP BY 
        kt.keyword
),
MovieCompanyDetails AS (
    SELECT 
        a.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        aka_title AS a ON mc.movie_id = a.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)
SELECT 
    ms.movie_title,
    ms.total_cast,
    ms.earliest_release,
    ms.latest_release,
    ks.keyword,
    ks.movies_count,
    mcd.company_name,
    mcd.company_type
FROM 
    MovieStatistics AS ms
JOIN 
    KeywordStats AS ks ON ms.movie_title LIKE '%' || ks.keyword || '%'
JOIN 
    MovieCompanyDetails AS mcd ON ms.movie_title IN (SELECT title FROM aka_title WHERE movie_id = mcd.movie_id)
WHERE 
    ms.total_cast > 5
ORDER BY 
    ms.latest_release DESC, 
    ks.movies_count DESC;
