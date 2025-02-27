
WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank,
        t.id
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
CastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_details
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieSummary AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        ct.total_cast,
        ct.cast_details,
        STRING_AGG(DISTINCT rt.movie_keyword, ', ') AS keywords
    FROM 
        RankedTitles AS rt
    JOIN 
        CastInfo AS ct ON rt.id = ct.movie_id
    GROUP BY 
        rt.movie_title, rt.production_year, ct.total_cast, ct.cast_details
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.total_cast,
    ms.cast_details,
    ms.keywords
FROM 
    MovieSummary AS ms
WHERE 
    ms.total_cast > 3
ORDER BY 
    ms.production_year DESC, ms.movie_title;
