
WITH MovieNames AS (
    SELECT 
        a.title AS Title,
        a.production_year AS ProductionYear,
        c.name AS CompanyName,
        ARRAY_AGG(DISTINCT r.role ORDER BY r.role) AS Roles
    FROM aka_title a
    JOIN movie_companies mc ON mc.movie_id = a.id
    JOIN company_name c ON c.id = mc.company_id
    JOIN complete_cast cc ON cc.movie_id = a.id
    JOIN cast_info ci ON ci.id = cc.subject_id
    JOIN role_type r ON r.id = ci.role_id
    WHERE a.production_year >= 2000
    GROUP BY a.id, a.title, a.production_year, c.name
),
KeywordStats AS (
    SELECT 
        m.id AS MovieID,
        k.keyword AS Keyword,
        COUNT(mk.keyword_id) AS Occurrences
    FROM aka_title m
    JOIN movie_keyword mk ON mk.movie_id = m.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
    GROUP BY m.id, k.keyword
),
MostFrequentKeywords AS (
    SELECT 
        k.Keyword,
        SUM(k.Occurrences) AS TotalOccurrences
    FROM KeywordStats k
    GROUP BY k.Keyword
    ORDER BY TotalOccurrences DESC
    LIMIT 5
)
SELECT 
    mn.Title,
    mn.ProductionYear,
    mn.CompanyName,
    mn.Roles,
    mf.Keyword,
    mf.TotalOccurrences
FROM MovieNames mn
JOIN MostFrequentKeywords mf ON mf.Keyword IN (
    SELECT ks.Keyword FROM KeywordStats ks WHERE ks.MovieID IN (SELECT a.id FROM aka_title a WHERE a.production_year >= 2000)
)
ORDER BY mn.ProductionYear DESC, mf.TotalOccurrences DESC;
